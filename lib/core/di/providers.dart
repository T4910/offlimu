import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/config/app_config.dart';
import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/entities/node_identity.dart';
import 'package:offlimu/domain/entities/node_public_identity.dart';
import 'package:offlimu/domain/entities/peer_contact.dart';
import 'package:offlimu/domain/entities/sync_job_history_entry.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/chat_message_repository.dart';
import 'package:offlimu/domain/repositories/peer_repository.dart';
import 'package:offlimu/domain/repositories/sync_job_repository.dart';
import 'package:offlimu/domain/services/discovery_adapter.dart';
import 'package:offlimu/domain/services/device_conditions_service.dart';
import 'package:offlimu/domain/services/logger_service.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/services/crypto_service.dart';
import 'package:offlimu/domain/services/node_identity_store.dart';
import 'package:offlimu/domain/services/sync_api.dart';
import 'package:offlimu/domain/services/transport_adapter.dart';
import 'package:offlimu/domain/services/background_scheduler.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/use_cases/chat_message_bundle_mapper.dart';
import 'package:offlimu/domain/use_cases/prepare_bundle_content_use_case.dart';
import 'package:offlimu/domain/use_cases/receive_chat_message_use_case.dart';
import 'package:offlimu/domain/use_cases/send_chat_message_use_case.dart';
import 'package:offlimu/domain/use_cases/send_file_transfer_use_case.dart';
import 'package:offlimu/infrastructure/db/app_database.dart' hide PeerContact;
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';
import 'package:offlimu/infrastructure/db/drift_chat_message_repository.dart';
import 'package:offlimu/infrastructure/db/drift_peer_repository.dart';
import 'package:offlimu/infrastructure/db/drift_sync_job_repository.dart';
import 'package:offlimu/infrastructure/content/local_file_content_store.dart';
import 'package:offlimu/infrastructure/crypto/ed25519_bundle_signature_service.dart';
import 'package:offlimu/infrastructure/crypto/ed25519_crypto_service.dart';
import 'package:offlimu/infrastructure/device/plugin_device_conditions_service.dart';
import 'package:offlimu/infrastructure/discovery/lan_broadcast_discovery_adapter.dart';
import 'package:offlimu/infrastructure/discovery/nsd_discovery_adapter.dart';
import 'package:offlimu/infrastructure/identity/secure_node_identity_store.dart';
import 'package:offlimu/infrastructure/logging/structured_logger.dart';
import 'package:offlimu/infrastructure/scheduler/in_app_background_scheduler.dart';
import 'package:offlimu/infrastructure/scheduler/workmanager_background_scheduler.dart';
import 'package:offlimu/infrastructure/settings/database_maintenance_store.dart';
import 'package:offlimu/infrastructure/settings/gateway_sync_preference_store.dart';
import 'package:offlimu/infrastructure/sync/dio_sync_api.dart';
import 'package:offlimu/infrastructure/transport/tcp_socket_transport_adapter.dart';
import 'package:offlimu/core/error/app_error_boundary.dart';
import 'package:offlimu/core/error/app_error_log_store.dart';
import 'package:offlimu/node_runtime/gateway_sync_coordinator.dart';
import 'package:offlimu/node_runtime/node_runtime.dart';
import 'package:offlimu/node_runtime/node_runtime_state.dart';
import 'package:offlimu/node_runtime/queue_pruning.dart';
import 'package:offlimu/node_runtime/sync_engine.dart';

final AppConfig _appConfig = AppConfig.fromEnvironment();
const String _scheduledSyncTaskId = 'scheduled_sync';
const String _scheduledCleanupTaskId = 'scheduled_cleanup';
const String _scheduledRetryTaskId = 'scheduled_retry';
const Duration _scheduledSyncFrequency = Duration(minutes: 15);
const Duration _scheduledCleanupFrequency = Duration(minutes: 30);
const Duration _scheduledRetryFrequency = Duration(minutes: 1);

final Provider<NodeIdentity> localNodeIdentityProvider = Provider<NodeIdentity>(
  (ref) =>
      NodeIdentity(nodeId: _appConfig.localNodeId, displayName: 'OffLiMU Node'),
);

final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (ref) => _appConfig,
);

final Provider<LoggerService> loggerServiceProvider = Provider<LoggerService>(
  (ref) => const StructuredLogger(),
);

final Provider<CryptoService> cryptoServiceProvider = Provider<CryptoService>(
  (ref) => Ed25519CryptoService(),
);

final Provider<NodeIdentityStore> nodeIdentityStoreProvider =
    Provider<NodeIdentityStore>((ref) => SecureNodeIdentityStore());

final Provider<BundleSignatureService> bundleSignatureServiceProvider =
    Provider<BundleSignatureService>((ref) {
      return Ed25519BundleSignatureService(
        cryptoService: ref.watch(cryptoServiceProvider),
        nodeIdentityStore: ref.watch(nodeIdentityStoreProvider),
      );
    });

final FutureProvider<NodePublicIdentity> nodePublicIdentityProvider =
    FutureProvider<NodePublicIdentity>((ref) {
      final identity = ref.watch(localNodeIdentityProvider);
      final store = ref.watch(nodeIdentityStoreProvider);
      return store.loadOrCreate(
        nodeId: identity.nodeId,
        displayName: identity.displayName,
      );
    });

final Provider<void> nodeIdentityBootstrapProvider = Provider<void>((ref) {
  if (_isRunningInWidgetTest()) {
    return;
  }

  ref.watch(nodePublicIdentityProvider);
});

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final Provider<BundleRepository> bundleRepositoryProvider =
    Provider<BundleRepository>(
      (ref) => DriftBundleRepository(
        ref.watch(appDatabaseProvider),
        localNodeId: _appConfig.localNodeId,
      ),
    );

final Provider<ContentStore> contentStoreProvider = Provider<ContentStore>(
  (ref) =>
      LocalFileContentStore(maxStoreBytes: _appConfig.contentStoreMaxBytes),
);

final Provider<PrepareBundleContentUseCase>
prepareBundleContentUseCaseProvider = Provider<PrepareBundleContentUseCase>(
  (ref) => PrepareBundleContentUseCase(
    bundles: ref.watch(bundleRepositoryProvider),
    contentStore: ref.watch(contentStoreProvider),
  ),
);

final Provider<ChatMessageBundleMapper> chatMessageBundleMapperProvider =
    Provider<ChatMessageBundleMapper>((ref) => const ChatMessageBundleMapper());

final Provider<SendChatMessageUseCase> sendChatMessageUseCaseProvider =
    Provider<SendChatMessageUseCase>(
      (ref) => SendChatMessageUseCase(
        bundles: ref.watch(bundleRepositoryProvider),
        prepareBundleContent: ref.watch(prepareBundleContentUseCaseProvider),
        mapper: ref.watch(chatMessageBundleMapperProvider),
        bundleSignatureService: ref.watch(bundleSignatureServiceProvider),
      ),
    );

final Provider<SendFileTransferUseCase> sendFileTransferUseCaseProvider =
    Provider<SendFileTransferUseCase>(
      (ref) => SendFileTransferUseCase(
        bundles: ref.watch(bundleRepositoryProvider),
        prepareBundleContent: ref.watch(prepareBundleContentUseCaseProvider),
        bundleSignatureService: ref.watch(bundleSignatureServiceProvider),
      ),
    );

final Provider<ReceiveChatMessageUseCase> receiveChatMessageUseCaseProvider =
    Provider<ReceiveChatMessageUseCase>(
      (ref) => ReceiveChatMessageUseCase(
        mapper: ref.watch(chatMessageBundleMapperProvider),
      ),
    );

final Provider<BackgroundScheduler> backgroundSchedulerProvider =
    Provider<BackgroundScheduler>((ref) {
      final bool mobileTarget =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

      if (mobileTarget) {
        return WorkmanagerBackgroundScheduler();
      }

      final scheduler = InAppBackgroundScheduler(
        onTask: (taskId) => _runScheduledTask(ref, taskId),
      );
      ref.onDispose(() {
        unawaited(scheduler.dispose());
      });
      return scheduler;
    });

final Provider<void> backgroundTaskBootstrapProvider = Provider<void>((ref) {
  if (_isRunningInWidgetTest()) {
    return;
  }

  final scheduler = ref.watch(backgroundSchedulerProvider);
  final bool supportsRetryTask = scheduler is InAppBackgroundScheduler;

  unawaited(
    scheduler.registerPeriodicTask(
      taskId: _scheduledSyncTaskId,
      frequency: _scheduledSyncFrequency,
    ),
  );
  unawaited(
    scheduler.registerPeriodicTask(
      taskId: _scheduledCleanupTaskId,
      frequency: _scheduledCleanupFrequency,
    ),
  );
  if (supportsRetryTask) {
    unawaited(
      scheduler.registerPeriodicTask(
        taskId: _scheduledRetryTaskId,
        frequency: _scheduledRetryFrequency,
      ),
    );
  }

  ref.onDispose(() {
    unawaited(scheduler.unregisterTask(_scheduledSyncTaskId));
    unawaited(scheduler.unregisterTask(_scheduledCleanupTaskId));
    if (supportsRetryTask) {
      unawaited(scheduler.unregisterTask(_scheduledRetryTaskId));
    }
  });
});

final Provider<ChatMessageRepository> chatMessageRepositoryProvider =
    Provider<ChatMessageRepository>(
      (ref) => DriftChatMessageRepository(ref.watch(appDatabaseProvider)),
    );

final Provider<PeerRepository> peerRepositoryProvider =
    Provider<PeerRepository>(
      (ref) => DriftPeerRepository(ref.watch(appDatabaseProvider)),
    );

final Provider<SyncJobRepository> syncJobRepositoryProvider =
    Provider<SyncJobRepository>(
      (ref) => DriftSyncJobRepository(ref.watch(appDatabaseProvider)),
    );

final StreamProvider<List<Bundle>> pendingBundlesProvider =
    StreamProvider<List<Bundle>>(
      (ref) => ref.watch(bundleRepositoryProvider).watchPendingBundles(),
    );

final StreamProvider<List<ChatMessage>> chatMessagesProvider =
    StreamProvider<List<ChatMessage>>(
      (ref) => ref
          .watch(chatMessageRepositoryProvider)
          .watchRecentMessages(limit: 200),
    );

final StreamProviderFamily<List<ChatMessage>, int> chatMessagesByLimitProvider =
    StreamProvider.family<List<ChatMessage>, int>(
      (ref, limit) => ref
          .watch(chatMessageRepositoryProvider)
          .watchRecentMessages(limit: limit),
    );

final StreamProvider<List<PeerContact>> peerContactsProvider =
    StreamProvider<List<PeerContact>>(
      (ref) => ref.watch(peerRepositoryProvider).watchPeers(),
    );

final StreamProvider<List<SyncJobHistoryEntry>> recentSyncJobsProvider =
    StreamProvider<List<SyncJobHistoryEntry>>(
      (ref) => ref.watch(syncJobRepositoryProvider).watchRecentRuns(limit: 10),
    );

final StreamProvider<List<AckAuditEvent>> recentAckEventsProvider =
    StreamProvider<List<AckAuditEvent>>(
      (ref) =>
          ref.watch(bundleRepositoryProvider).watchRecentAckEvents(limit: 50),
    );

final StreamProvider<List<ContentMetadataRecord>>
recentContentMetadataProvider = StreamProvider<List<ContentMetadataRecord>>(
  (ref) => ref
      .watch(bundleRepositoryProvider)
      .watchRecentContentMetadata(limit: 100),
);

final StreamProvider<int> pendingBundleCountProvider = StreamProvider<int>(
  (ref) => ref
      .watch(bundleRepositoryProvider)
      .watchPendingBundles()
      .map((List<Bundle> bundles) => bundles.length),
);

final Provider<DiscoveryAdapter> discoveryAdapterProvider =
    Provider<DiscoveryAdapter>((ref) {
      final fallback = LanBroadcastDiscoveryAdapter(
        localNodeId: _appConfig.localNodeId,
        transportPort: _appConfig.transportPort,
        discoveryPort: _appConfig.discoveryPort,
      );

      return NsdDiscoveryAdapter(
        localNodeId: _appConfig.localNodeId,
        transportPort: _appConfig.transportPort,
        fallback: fallback,
      );
    });

final Provider<TransportAdapter> transportAdapterProvider =
    Provider<TransportAdapter>(
      (ref) => TcpSocketTransportAdapter(listenPort: _appConfig.transportPort),
    );

final Provider<SyncApi> syncApiProvider = Provider<SyncApi>(
  (ref) => DioSyncApi(
    baseUrl: _appConfig.syncBaseUrl,
    mockMode: _appConfig.syncMockMode,
  ),
);

final Provider<DeviceConditionsService> deviceConditionsServiceProvider =
    Provider<DeviceConditionsService>((ref) => PluginDeviceConditionsService());

final Provider<AppErrorLogStore> appErrorLogStoreProvider =
    Provider<AppErrorLogStore>((ref) => appErrorLogStore);

final Provider<SyncEngine> syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    localNodeId: _appConfig.localNodeId,
    bundles: ref.watch(bundleRepositoryProvider),
    syncApi: ref.watch(syncApiProvider),
    syncJobs: ref.watch(syncJobRepositoryProvider),
    deviceConditions: ref.watch(deviceConditionsServiceProvider),
    logger: ref.watch(loggerServiceProvider),
    devicePolicy: SyncDevicePolicy(
      allowMeteredNetwork: _appConfig.syncAllowMeteredNetwork,
      minBatteryPercent: _appConfig.syncMinBatteryPercent,
      requireChargingWhenLowBattery:
          _appConfig.syncRequireChargingWhenLowBattery,
    ),
    maxHopCount: _appConfig.maxBundleHopCount,
  ),
);

final StateProvider<AsyncValue<SyncRunResult>?> syncRunStateProvider =
    StateProvider<AsyncValue<SyncRunResult>?>((ref) => null);

final StateProvider<GatewaySyncCoordinatorStatus> gatewaySyncStatusProvider =
    StateProvider<GatewaySyncCoordinatorStatus>(
      (ref) => const GatewaySyncCoordinatorStatus(),
    );

final StateProvider<bool> gatewayEnabledProvider = StateProvider<bool>(
  (ref) => true,
);

final Provider<GatewaySyncPreferenceStore> gatewaySyncPreferenceStoreProvider =
    Provider<GatewaySyncPreferenceStore>((ref) {
      return const GatewaySyncPreferenceStore();
    });

final Provider<DatabaseMaintenanceStore> databaseMaintenanceStoreProvider =
    Provider<DatabaseMaintenanceStore>((ref) {
      return const DatabaseMaintenanceStore();
    });

final Provider<void> gatewaySyncPreferenceBootstrapProvider = Provider<void>((
  ref,
) {
  if (_isRunningInWidgetTest()) {
    return;
  }

  final preferenceStore = ref.watch(gatewaySyncPreferenceStoreProvider);

  unawaited(
    Future<void>(() async {
      final stored = await preferenceStore.readEnabled();
      if (stored != null) {
        ref.read(gatewayEnabledProvider.notifier).state = stored;
      }
    }),
  );

  ref.listen<bool>(gatewayEnabledProvider, (previous, next) {
    if (previous == next) {
      return;
    }
    unawaited(preferenceStore.writeEnabled(next));
  });
});

final Provider<GatewaySyncCoordinator> gatewaySyncCoordinatorProvider =
    Provider<GatewaySyncCoordinator>((ref) {
      final coordinator = GatewaySyncCoordinator(
        syncEngine: ref.watch(syncEngineProvider),
        onState: (value) {
          ref.read(syncRunStateProvider.notifier).state = value;
        },
        onStatus: (status) {
          ref.read(gatewaySyncStatusProvider.notifier).state = status;
        },
      );

      ref.listen<bool>(gatewayEnabledProvider, (previous, next) {
        if (next != previous) {
          ref.read(syncRunStateProvider.notifier).state = null;
        }
        unawaited(coordinator.setEnabled(next));
      });

      ref.onDispose(() {
        unawaited(coordinator.dispose());
      });

      return coordinator;
    });

final Provider<NodeRuntime> nodeRuntimeProvider = Provider<NodeRuntime>((ref) {
  final NodeRuntime runtime = NodeRuntime(
    localNodeId: _appConfig.localNodeId,
    discovery: ref.watch(discoveryAdapterProvider),
    transport: ref.watch(transportAdapterProvider),
    bundles: ref.watch(bundleRepositoryProvider),
    peers: ref.watch(peerRepositoryProvider),
    contentStore: ref.watch(contentStoreProvider),
    bundleSignatureService: ref.watch(bundleSignatureServiceProvider),
    maxHopCount: _appConfig.maxBundleHopCount,
    logger: ref.watch(loggerServiceProvider),
  );
  ref.onDispose(() {
    unawaited(runtime.dispose());
  });
  return runtime;
});

final StreamProvider<RuntimeHealth> runtimeHealthProvider =
    StreamProvider<RuntimeHealth>((ref) async* {
      final runtime = ref.watch(nodeRuntimeProvider);
      yield runtime.health;
      yield* runtime.healthStream;
    });

final StreamProvider<int> discoveredPeerCountProvider = StreamProvider<int>((
  ref,
) async* {
  final runtime = ref.watch(nodeRuntimeProvider);
  yield runtime.peerCount;
  yield* runtime.peerCountStream;
});

final StreamProvider<RuntimeTelemetry> runtimeTelemetryProvider =
    StreamProvider<RuntimeTelemetry>((ref) async* {
      final runtime = ref.watch(nodeRuntimeProvider);
      yield runtime.telemetry;
      yield* runtime.telemetryStream;
    });

final Provider<AsyncValue<NodeRuntimeState>> nodeRuntimeStateProvider =
    Provider<AsyncValue<NodeRuntimeState>>((ref) {
      final identity = ref.watch(localNodeIdentityProvider);
      final pendingCount = ref.watch(pendingBundleCountProvider);
      final health = ref.watch(runtimeHealthProvider);
      final discoveredPeers = ref.watch(discoveredPeerCountProvider);
      final telemetry = ref.watch(runtimeTelemetryProvider);
      final gatewayEnabled = ref.watch(gatewayEnabledProvider);

      if (pendingCount.hasError) {
        return AsyncValue<NodeRuntimeState>.error(
          pendingCount.error!,
          pendingCount.stackTrace ?? StackTrace.current,
        );
      }
      if (health.hasError) {
        return AsyncValue<NodeRuntimeState>.error(
          health.error!,
          health.stackTrace ?? StackTrace.current,
        );
      }
      if (discoveredPeers.hasError) {
        return AsyncValue<NodeRuntimeState>.error(
          discoveredPeers.error!,
          discoveredPeers.stackTrace ?? StackTrace.current,
        );
      }
      if (telemetry.hasError) {
        return AsyncValue<NodeRuntimeState>.error(
          telemetry.error!,
          telemetry.stackTrace ?? StackTrace.current,
        );
      }

      final int? pendingValue = pendingCount.valueOrNull;
      final RuntimeHealth? healthValue = health.valueOrNull;
      final int? peerValue = discoveredPeers.valueOrNull;
      final RuntimeTelemetry? telemetryValue = telemetry.valueOrNull;

      if (pendingValue == null ||
          healthValue == null ||
          peerValue == null ||
          telemetryValue == null) {
        return const AsyncValue<NodeRuntimeState>.loading();
      }

      return AsyncValue<NodeRuntimeState>.data(
        NodeRuntimeState(
          identity: identity,
          health: healthValue,
          discoveredPeers: peerValue,
          pendingBundles: pendingValue,
          gatewayEnabled: gatewayEnabled,
          telemetry: telemetryValue,
        ),
      );
    });

Future<void> _runScheduledTask(Ref ref, String taskId) async {
  if (taskId == _scheduledSyncTaskId) {
    final gatewayEnabled = ref.read(gatewayEnabledProvider);
    try {
      await ref
          .read(gatewaySyncCoordinatorProvider)
          .runManual(gatewayEnabled: gatewayEnabled);
    } catch (_) {
      // Sync failures are already reflected in sync history and status providers.
    }
    return;
  }

  if (taskId == _scheduledCleanupTaskId) {
    await _cleanupExpiredBundles(ref);
    return;
  }

  if (taskId == _scheduledRetryTaskId) {
    await ref.read(nodeRuntimeProvider).flushPendingNow();
  }
}

bool _isRunningInWidgetTest() {
  final binding = WidgetsBinding.instance;
  final bindingType = binding.runtimeType.toString();
  return bindingType.contains('TestWidgetsFlutterBinding') ||
      bindingType.contains('AutomatedTestWidgetsFlutterBinding') ||
      bindingType.contains('LiveTestWidgetsFlutterBinding');
}

Future<void> _cleanupExpiredBundles(Ref ref) async {
  final bundles = ref.read(bundleRepositoryProvider);
  final pending = await bundles.getPendingBundles();

  for (final bundle in pending.where((bundle) => bundle.isExpired)) {
    await bundles.markRejected(
      bundle.bundleId,
      reason: 'Bundle expired during scheduled cleanup (TTL exceeded).',
    );
  }

  final remainingPending = await bundles.getPendingBundles();
  final pruned = selectPendingBundlesForPruning(
    remainingPending,
    maxPendingBundles: _appConfig.maxPendingBundles,
  );

  for (final bundle in pruned) {
    await bundles.markRejected(
      bundle.bundleId,
      reason: 'Bundle pruned by queue overflow policy.',
    );
  }

  await _runDatabaseMaintenance(ref);
}

Future<void> _runDatabaseMaintenance(Ref ref) async {
  final AppDatabase db = ref.read(appDatabaseProvider);
  final DatabaseMaintenanceStore store = ref.read(
    databaseMaintenanceStoreProvider,
  );
  final AppErrorLogStore errorLogStore = ref.read(appErrorLogStoreProvider);

  final bool healthy = await db.runHealthCheck();
  if (!healthy) {
    errorLogStore.record(
      source: 'db_health',
      error: StateError('SQLite quick_check failed'),
      stackTrace: StackTrace.current,
    );
    return;
  }

  final DateTime now = DateTime.now();
  final DateTime? lastVacuumAt = await store.readLastVacuumAt();
  if (!_shouldRunVacuum(lastVacuumAt: lastVacuumAt, now: now)) {
    return;
  }

  try {
    await db.runVacuum();
    await store.writeLastVacuumAt(now);
  } catch (error, stackTrace) {
    errorLogStore.record(
      source: 'db_vacuum',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

bool _shouldRunVacuum({
  required DateTime? lastVacuumAt,
  required DateTime now,
}) {
  if (_appConfig.dbVacuumIntervalMinutes <= 0) {
    return true;
  }
  if (lastVacuumAt == null) {
    return true;
  }
  return now.difference(lastVacuumAt) >=
      Duration(minutes: _appConfig.dbVacuumIntervalMinutes);
}
