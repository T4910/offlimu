import 'package:offlimu/core/config/app_config.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/services/background_scheduler.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/commerce_repository.dart';
import 'package:offlimu/domain/repositories/sync_job_repository.dart';
import 'package:offlimu/domain/repositories/wallet_repository.dart';
import 'package:offlimu/domain/repositories/web_search_repository.dart';
import 'package:offlimu/domain/services/device_conditions_service.dart';
import 'package:offlimu/domain/services/logger_service.dart';
import 'package:offlimu/domain/services/crypto_service.dart';
import 'package:offlimu/domain/services/node_identity_store.dart';
import 'package:offlimu/domain/services/sync_api.dart';
import 'package:offlimu/domain/use_cases/prepare_bundle_content_use_case.dart';
import 'package:offlimu/domain/use_cases/send_file_transfer_use_case.dart';
import 'package:offlimu/domain/use_cases/wallet_event_bundle_mapper.dart';
import 'package:offlimu/domain/use_cases/wallet_sync_reconciliation_service.dart';
import 'package:offlimu/domain/use_cases/web_search_result_ingestion_service.dart';
import 'package:offlimu/infrastructure/content/local_file_content_store.dart';
import 'package:offlimu/infrastructure/crypto/ed25519_bundle_signature_service.dart';
import 'package:offlimu/infrastructure/crypto/ed25519_crypto_service.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';
import 'package:offlimu/infrastructure/db/drift_commerce_repository.dart';
import 'package:offlimu/infrastructure/db/drift_sync_job_repository.dart';
import 'package:offlimu/infrastructure/db/drift_wallet_repository.dart';
import 'package:offlimu/infrastructure/db/drift_web_search_repository.dart';
import 'package:offlimu/infrastructure/device/plugin_device_conditions_service.dart';
import 'package:offlimu/infrastructure/identity/secure_node_identity_store.dart';
import 'package:offlimu/infrastructure/logging/structured_logger.dart';
import 'package:offlimu/infrastructure/settings/gateway_sync_preference_store.dart';
import 'package:offlimu/infrastructure/sync/dio_sync_api.dart';
import 'package:offlimu/node_runtime/sync_engine.dart';
import 'package:workmanager/workmanager.dart';

final AppConfig _appConfig = AppConfig.fromEnvironment();
const LoggerService _logger = StructuredLogger();

@pragma('vm:entry-point')
void offlimuBackgroundTaskDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final normalizedTask = _normalizeTaskId(task);
    await _executeBackgroundTask(normalizedTask);
    return true;
  });
}

String _normalizeTaskId(String taskId) {
  const prefix = 'offlimu.';
  if (taskId.startsWith(prefix)) {
    return taskId.substring(prefix.length);
  }
  return taskId;
}

Future<void> _executeBackgroundTask(String taskId) async {
  switch (taskId) {
    case 'scheduled_sync':
      await _runBackgroundSync();
      return;
    case 'scheduled_cleanup':
      await _runBackgroundCleanup();
      return;
    default:
      return;
  }
}

Future<void> _runBackgroundSync() async {
  final preferenceStore = const GatewaySyncPreferenceStore();
  final bool gatewayEnabled = await preferenceStore.readEnabledOrDefault(
    defaultValue: true,
  );
  if (!gatewayEnabled) {
    return;
  }

  final db = AppDatabase();
  final BundleRepository bundles = DriftBundleRepository(
    db,
    localNodeId: _appConfig.localNodeId,
  );
  final SyncApi syncApi = DioSyncApi(
    baseUrl: _appConfig.syncBaseUrl,
    mockMode: _appConfig.syncMockMode,
  );
  final SyncJobRepository syncJobs = DriftSyncJobRepository(db);
  final WalletRepository walletRepository = DriftWalletRepository(db);
  final WebSearchRepository webSearchRepository = DriftWebSearchRepository(db);
  final CommerceRepository commerceRepository = DriftCommerceRepository(db);
  final ContentStore contentStore = LocalFileContentStore(
    maxStoreBytes: _appConfig.contentStoreMaxBytes,
  );
  final CryptoService cryptoService = Ed25519CryptoService();
  final NodeIdentityStore nodeIdentityStore = SecureNodeIdentityStore();
  final BundleSignatureService bundleSignatureService =
      Ed25519BundleSignatureService(
        cryptoService: cryptoService,
        nodeIdentityStore: nodeIdentityStore,
      );
  final prepareBundleContent = PrepareBundleContentUseCase(
    bundles: bundles,
    contentStore: contentStore,
  );
  final sendFileTransfer = SendFileTransferUseCase(
    bundles: bundles,
    prepareBundleContent: prepareBundleContent,
    bundleSignatureService: bundleSignatureService,
  );
  final walletSyncReconciliationService = WalletSyncReconciliationService(
    walletRepository: walletRepository,
    mapper: const WalletEventBundleMapper(),
  );
  final webSearchResultIngestionService = WebSearchResultIngestionService(
    sendFileTransfer: sendFileTransfer,
    webSearchRepository: webSearchRepository,
    bundleRepository: bundles,
    bundleSignatureService: bundleSignatureService,
  );
  final DeviceConditionsService deviceConditions =
      PluginDeviceConditionsService();

  final engine = SyncEngine(
    localNodeId: _appConfig.localNodeId,
    bundles: bundles,
    syncApi: syncApi,
    syncJobs: syncJobs,
    deviceConditions: deviceConditions,
    walletSyncReconciliationService: walletSyncReconciliationService,
    webSearchResultIngestionService: webSearchResultIngestionService,
    commerceRepository: commerceRepository,
    logger: _logger,
    devicePolicy: SyncDevicePolicy(
      allowMeteredNetwork: _appConfig.syncAllowMeteredNetwork,
      minBatteryPercent: _appConfig.syncMinBatteryPercent,
      requireChargingWhenLowBattery:
          _appConfig.syncRequireChargingWhenLowBattery,
    ),
    maxHopCount: _appConfig.maxBundleHopCount,
  );

  try {
    await engine.syncNow(gatewayEnabled: gatewayEnabled);
  } catch (_) {
    // syncNow persists failures to sync history, so background runner can safely continue.
  } finally {
    await db.close();
  }
}

Future<void> _runBackgroundCleanup() async {
  final db = AppDatabase();
  final BundleRepository bundles = DriftBundleRepository(
    db,
    localNodeId: _appConfig.localNodeId,
  );

  try {
    final pending = await bundles.getPendingBundles();
    for (final bundle in pending.where((bundle) => bundle.isExpired)) {
      await bundles.markRejected(
        bundle.bundleId,
        reason: 'Bundle expired during background cleanup (TTL exceeded).',
      );
    }
  } finally {
    await db.close();
  }
}

class WorkmanagerBackgroundScheduler implements BackgroundScheduler {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    try {
      await Workmanager().initialize(offlimuBackgroundTaskDispatcher);
      _initialized = true;
    } on UnimplementedError {
      _initialized = false;
    }
  }

  @override
  Future<void> registerPeriodicTask({
    required String taskId,
    required Duration frequency,
  }) async {
    await _ensureInitialized();

    if (!_initialized) {
      return;
    }

    final Duration clampedFrequency = frequency < const Duration(minutes: 15)
        ? const Duration(minutes: 15)
        : frequency;

    try {
      await Workmanager().registerPeriodicTask(
        taskId,
        'offlimu.$taskId',
        frequency: clampedFrequency,
      );
    } on UnimplementedError {
      // Platform does not provide workmanager in this runtime (e.g. tests).
    }
  }

  @override
  Future<void> unregisterTask(String taskId) async {
    try {
      await Workmanager().cancelByUniqueName(taskId);
    } on UnimplementedError {
      // Platform does not provide workmanager in this runtime (e.g. tests).
    }
  }
}
