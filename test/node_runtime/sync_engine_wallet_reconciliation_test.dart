import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/sync_contract.dart';
import 'package:offlimu/domain/entities/sync_job_history_entry.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart' as ledger;
import 'package:offlimu/domain/repositories/sync_job_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/services/device_conditions_service.dart';
import 'package:offlimu/domain/services/sync_api.dart';
import 'package:offlimu/domain/use_cases/initiate_wallet_spend_use_case.dart';
import 'dart:convert';
import 'package:offlimu/domain/use_cases/wallet_event_bundle_mapper.dart';
import 'package:offlimu/domain/use_cases/wallet_sync_reconciliation_service.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';
import 'package:offlimu/infrastructure/db/drift_wallet_repository.dart';
import 'package:offlimu/node_runtime/sync_engine.dart';

void main() {
  test('sync uploads a pending spend and applies a confirmed settlement', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();

    final walletRepository = DriftWalletRepository(db);
    // Seed opening grant so spends have balance in tests.
    await walletRepository.appendEntry(
      ledger.WalletLedgerEntry(
        entryId: 'opening-grant',
        kind: ledger.WalletLedgerEventKind.openingGrant,
        title: 'Opening Grant',
        subtitle: 'Test seed',
        amountMinorUnits: 5000,
        balanceImpactMinorUnits: 5000,
        status: ledger.WalletLedgerStatus.confirmed,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
    );
    // Seed opening grant so spends have balance in tests.
    await walletRepository.appendEntry(
      ledger.WalletLedgerEntry(
        entryId: 'opening-grant',
        kind: ledger.WalletLedgerEventKind.openingGrant,
        title: 'Opening Grant',
        subtitle: 'Test seed',
        amountMinorUnits: 5000,
        balanceImpactMinorUnits: 5000,
        status: ledger.WalletLedgerStatus.confirmed,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
    );
    final bundleRepository = DriftBundleRepository(db, localNodeId: 'node-local-001');
    final mapper = WalletEventBundleMapper();
    final signatureService = _PassThroughSignatureService();
    final spendUseCase = InitiateWalletSpendUseCase(
      walletRepository: walletRepository,
      bundleRepository: bundleRepository,
      bundleSignatureService: signatureService,
      now: () => now,
    );

    final spendResult = await spendUseCase.initiate(
      localNodeId: 'node-local-001',
      recipientNodeId: 'node-remote-123',
      amountMinorUnits: 1250,
      memo: 'Sync settlement test',
    );

    final walletSyncReconciliationService = WalletSyncReconciliationService(
      walletRepository: walletRepository,
      mapper: mapper,
      now: () => DateTime.fromMillisecondsSinceEpoch(1700001000000),
    );
    final fakeSyncApi = _FakeSyncApi(
      uploadResult: SyncUploadResult(
        acknowledgedBundleIds: <String>[spendResult.bundle.bundleId],
        rejections: const <SyncRejection>[],
      ),
      fetchResult: SyncFetchResult(
        bundles: <Bundle>[
          mapper.toConfirmationBundle(
            bundleId: 'wallet-confirmation-1',
            localNodeId: 'server-gateway',
            sourceSpendBundleId: spendResult.bundle.bundleId,
            recipientNodeId: 'node-remote-123',
            amountMinorUnits: 1250,
            createdAt: now.add(const Duration(minutes: 1)),
            memo: 'Sync settlement test',
          ),
        ],
      ),
    );
    final engine = SyncEngine(
      localNodeId: 'node-local-001',
      bundles: bundleRepository,
      syncApi: fakeSyncApi,
      syncJobs: _FakeSyncJobRepository(),
      deviceConditions: _AlwaysOnlineDeviceConditionsService(),
      walletSyncReconciliationService: walletSyncReconciliationService,
    );

    final result = await engine.syncNow(gatewayEnabled: true);
    final dashboard = await walletRepository.watchDashboard().first;

    expect(result.uploadedCount, 1);
    expect(result.downloadedCount, 1);
    expect(fakeSyncApi.uploadedBundles, hasLength(1));
    expect(fakeSyncApi.uploadedBundles.single.type, Bundle.typeWalletSpend);
    expect(dashboard.balanceMinorUnits, 3750);
    expect(dashboard.pendingSpendCount, 0);
    expect(
      dashboard.paymentEntries.any(
        (entry) =>
            entry.kind == ledger.WalletLedgerEventKind.spend &&
            entry.status == ledger.WalletLedgerStatus.confirmed &&
            entry.sourceBundleId == spendResult.bundle.bundleId,
      ),
      isTrue,
    );
  });

  test('sync records a rejected spend without changing the balance', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();

    final walletRepository = DriftWalletRepository(db);
    // Seed opening grant so spends have balance in tests.
    await walletRepository.appendEntry(
      ledger.WalletLedgerEntry(
        entryId: 'opening-grant',
        kind: ledger.WalletLedgerEventKind.openingGrant,
        title: 'Opening Grant',
        subtitle: 'Test seed',
        amountMinorUnits: 5000,
        balanceImpactMinorUnits: 5000,
        status: ledger.WalletLedgerStatus.confirmed,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
    );
    final bundleRepository = DriftBundleRepository(db, localNodeId: 'node-local-001');
    final mapper = WalletEventBundleMapper();
    final signatureService = _PassThroughSignatureService();
    final spendUseCase = InitiateWalletSpendUseCase(
      walletRepository: walletRepository,
      bundleRepository: bundleRepository,
      bundleSignatureService: signatureService,
      now: () => now,
    );

    final spendResult = await spendUseCase.initiate(
      localNodeId: 'node-local-001',
      recipientNodeId: 'node-remote-123',
      amountMinorUnits: 1500,
      memo: 'Rejected settlement test',
    );

    final walletSyncReconciliationService = WalletSyncReconciliationService(
      walletRepository: walletRepository,
      mapper: mapper,
      now: () => DateTime.fromMillisecondsSinceEpoch(1700004000000),
    );
    final fakeSyncApi = _FakeSyncApi(
      uploadResult: SyncUploadResult(
        acknowledgedBundleIds: const <String>[],
        rejections: <SyncRejection>[
          SyncRejection(
            bundleId: spendResult.bundle.bundleId,
            reason: 'Rejected by server policy',
          ),
        ],
      ),
      fetchResult: const SyncFetchResult(bundles: <Bundle>[]),
    );
    final engine = SyncEngine(
      localNodeId: 'node-local-001',
      bundles: bundleRepository,
      syncApi: fakeSyncApi,
      syncJobs: _FakeSyncJobRepository(),
      deviceConditions: _AlwaysOnlineDeviceConditionsService(),
      walletSyncReconciliationService: walletSyncReconciliationService,
    );

    final result = await engine.syncNow(gatewayEnabled: true);
    final dashboard = await walletRepository.watchDashboard().first;

    expect(result.uploadedCount, 1);
    expect(result.downloadedCount, 0);
    expect(fakeSyncApi.uploadedBundles, hasLength(1));
    expect(fakeSyncApi.uploadedBundles.single.type, Bundle.typeWalletSpend);
    expect(dashboard.balanceMinorUnits, 5000);
    expect(dashboard.pendingSpendCount, 0);
    expect(
      dashboard.paymentEntries.any(
        (entry) =>
            entry.kind == ledger.WalletLedgerEventKind.rejection &&
            entry.status == ledger.WalletLedgerStatus.rejected &&
            entry.sourceBundleId == spendResult.bundle.bundleId,
      ),
      isTrue,
    );
  });

  test('sync applies an inbound signed reward and credits the balance', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();

    final walletRepository = DriftWalletRepository(db);
    // Seed opening grant so reward tests start from a baseline.
    await walletRepository.appendEntry(
      ledger.WalletLedgerEntry(
        entryId: 'opening-grant',
        kind: ledger.WalletLedgerEventKind.openingGrant,
        title: 'Opening Grant',
        subtitle: 'Test seed',
        amountMinorUnits: 5000,
        balanceImpactMinorUnits: 5000,
        status: ledger.WalletLedgerStatus.confirmed,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
    );
    final bundleRepository = DriftBundleRepository(db, localNodeId: 'node-local-001');
    final mapper = WalletEventBundleMapper();
    // final signatureService = _PassThroughSignatureService();

    final walletSyncReconciliationService = WalletSyncReconciliationService(
      walletRepository: walletRepository,
      mapper: mapper,
      now: () => DateTime.fromMillisecondsSinceEpoch(1700005000000),
    );

    final rewardBundle = Bundle(
      bundleId: 'reward-1',
      type: Bundle.typeWalletReward,
      sourceNodeId: 'server-gateway',
      destinationNodeId: 'node-local-001',
      payload: jsonEncode(<String, Object?>{
        'kind': 'reward',
        'rewardKind': 'relay',
        'amountMinorUnits': 250,
        'createdAtMs': now.millisecondsSinceEpoch,
        'memo': 'Relay reward',
      }),
      appId: WalletEventBundleMapper.walletAppId,
      createdAt: now,
      ttlSeconds: 3600,
      signature: 'signed-by-server',
    );

    final fakeSyncApi = _FakeSyncApi(
      uploadResult: SyncUploadResult(
        acknowledgedBundleIds: const <String>[],
        rejections: const <SyncRejection>[],
      ),
      fetchResult: SyncFetchResult(
        bundles: <Bundle>[rewardBundle],
      ),
    );

    final engine = SyncEngine(
      localNodeId: 'node-local-001',
      bundles: bundleRepository,
      syncApi: fakeSyncApi,
      syncJobs: _FakeSyncJobRepository(),
      deviceConditions: _AlwaysOnlineDeviceConditionsService(),
      walletSyncReconciliationService: walletSyncReconciliationService,
    );

    final result = await engine.syncNow(gatewayEnabled: true);
    final dashboard = await walletRepository.watchDashboard().first;

    expect(result.uploadedCount, 0);
    expect(result.downloadedCount, 1);
    expect(dashboard.balanceMinorUnits, 5250);
    expect(
      dashboard.rewardEntries.any(
        (entry) => entry.kind == ledger.WalletLedgerEventKind.relayReward && entry.amountMinorUnits == 250,
      ),
      isTrue,
    );
  });
}

class _FakeSyncApi implements SyncApi {
  _FakeSyncApi({required this.uploadResult, required this.fetchResult});

  final SyncUploadResult uploadResult;
  final SyncFetchResult fetchResult;
  final List<Bundle> uploadedBundles = <Bundle>[];

  @override
  bool get mockMode => false;

  @override
  Future<SyncUploadResult> uploadBundles(List<Bundle> bundles) async {
    uploadedBundles.addAll(bundles);
    return uploadResult;
  }

  @override
  Future<SyncFetchResult> fetchRemoteBundles({required DateTime since}) async {
    return fetchResult;
  }
}

class _AlwaysOnlineDeviceConditionsService implements DeviceConditionsService {
  @override
  Future<DeviceConditionsSnapshot> read() async {
    return const DeviceConditionsSnapshot(
      connectionType: DeviceConnectionType.wifi,
      internetReachable: true,
      batteryLevelPercent: 100,
      isCharging: true,
    );
  }
}

class _FakeSyncJobRepository implements SyncJobRepository {
  @override
  Future<void> saveRun(SyncJobHistoryEntry entry) async {}

  @override
  Stream<List<SyncJobHistoryEntry>> watchRecentRuns({int limit = 20}) async* {
    yield const <SyncJobHistoryEntry>[];
  }
}

class _PassThroughSignatureService implements BundleSignatureService {
  @override
  Future<Bundle> sign({required Bundle bundle, required String nodeId}) async {
    return bundle.copyWith(signature: 'signed-by-$nodeId');
  }

  @override
  Future<bool> verify(Bundle bundle) async => true;
}
