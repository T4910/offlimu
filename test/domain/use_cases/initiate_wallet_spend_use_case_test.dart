import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/wallet_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/use_cases/initiate_wallet_spend_use_case.dart';

void main() {
  test(
    'initiates an offline wallet spend bundle and pending ledger entry',
    () async {
      final walletRepository = _FakeWalletRepository(_dashboard(5000));
      final bundleRepository = _FakeBundleRepository();
      final signatureService = _PassThroughSignatureService();
      final useCase = InitiateWalletSpendUseCase(
        walletRepository: walletRepository,
        bundleRepository: bundleRepository,
        bundleSignatureService: signatureService,
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final result = await useCase.initiate(
        localNodeId: 'node-local-001',
        recipientNodeId: 'node-remote-123',
        amountMinorUnits: 1250,
        memo: 'Test spend',
      );

      expect(result.bundle.type, Bundle.typeWalletSpend);
      expect(result.bundle.sourceNodeId, 'node-local-001');
      expect(result.bundle.destinationNodeId, 'node-remote-123');
      expect(result.pendingEntry.status, WalletLedgerStatus.pending);
      expect(result.pendingEntry.amountMinorUnits, -1250);
      expect(result.pendingEntry.sourceBundleId, result.bundle.bundleId);
      expect(bundleRepository.savedBundles, hasLength(1));
      expect(walletRepository.appendedEntries, hasLength(1));
    },
  );

  test('rejects spends that exceed available balance', () async {
    final walletRepository = _FakeWalletRepository(
      _dashboard(5000, availableBalanceMinorUnits: 1000),
    );
    final bundleRepository = _FakeBundleRepository();
    final signatureService = _PassThroughSignatureService();
    final useCase = InitiateWalletSpendUseCase(
      walletRepository: walletRepository,
      bundleRepository: bundleRepository,
      bundleSignatureService: signatureService,
    );

    expect(
      () => useCase.initiate(
        localNodeId: 'node-local-001',
        recipientNodeId: 'node-remote-123',
        amountMinorUnits: 1500,
      ),
      throwsStateError,
    );
  });
}

class _FakeWalletRepository implements WalletRepository {
  _FakeWalletRepository(this.dashboard);

  final WalletLedgerDashboard dashboard;
  final List<WalletLedgerEntry> appendedEntries = <WalletLedgerEntry>[];

  @override
  Future<void> appendEntry(WalletLedgerEntry entry) async {
    appendedEntries.add(entry);
  }

  @override
  Stream<WalletLedgerDashboard> watchDashboard({
    int recentLimit = 3,
    int rewardLimit = 4,
    int logLimit = 6,
  }) async* {
    yield dashboard;
  }
}

class _FakeBundleRepository implements BundleRepository {
  final List<Bundle> savedBundles = <Bundle>[];

  @override
  Future<void> deleteBundle(String bundleId) => throw UnimplementedError();

  @override
  Future<Bundle?> getById(String bundleId) async => null;

  @override
  Future<List<Bundle>> getAllBundles() => throw UnimplementedError();

  @override
  Future<ContentMetadataRecord?> getContentMetadata(String contentHash) =>
      throw UnimplementedError();

  @override
  Future<List<Bundle>> getPendingBundles() => throw UnimplementedError();

  @override
  Future<void> markAcknowledged(String bundleId) => throw UnimplementedError();

  @override
  Future<void> markRejected(String bundleId, {required String reason}) =>
      throw UnimplementedError();

  @override
  Future<void> markSendFailed(
    String bundleId, {
    required String errorMessage,
  }) => throw UnimplementedError();

  @override
  Future<void> markSent(String bundleId) => throw UnimplementedError();

  @override
  Future<void> resetForRetry(String bundleId) => throw UnimplementedError();

  @override
  Future<bool> recordAckReceipt(Bundle ackBundle) => throw UnimplementedError();

  @override
  Future<void> save(Bundle bundle) async {
    savedBundles.add(bundle);
  }

  @override
  Future<void> saveContentMetadata(ContentMetadataRecord metadata) =>
      throw UnimplementedError();

  @override
  Stream<List<AckAuditEvent>> watchRecentAckEvents({int limit = 20}) =>
      throw UnimplementedError();

  @override
  Stream<List<Bundle>> watchAllBundles() => throw UnimplementedError();

  @override
  Stream<List<ContentMetadataRecord>> watchRecentContentMetadata({
    int limit = 50,
  }) => throw UnimplementedError();

  @override
  Stream<List<Bundle>> watchBundlesByType(String type) =>
      throw UnimplementedError();

  @override
  Stream<List<Bundle>> watchPendingBundles() => throw UnimplementedError();
}

class _PassThroughSignatureService implements BundleSignatureService {
  @override
  Future<Bundle> sign({required Bundle bundle, required String nodeId}) async {
    return bundle.copyWith(signature: 'signed-by-$nodeId');
  }

  @override
  Future<bool> verify(Bundle bundle) async => true;
}

WalletLedgerDashboard _dashboard(
  int balanceMinorUnits, {
  int? availableBalanceMinorUnits,
}) {
  return WalletLedgerDashboard(
    balanceMinorUnits: balanceMinorUnits,
    availableBalanceMinorUnits: availableBalanceMinorUnits ?? balanceMinorUnits,
    relayRewardsMinorUnits: 0,
    gatewayRewardsMinorUnits: 0,
    rewardTotalMinorUnits: 0,
    pendingRewardMinorUnits: 0,
    pendingSpendCount: 0,
    pendingSpendMinorUnits: 0,
    trustScore: 0.0,
    participationGrade: '',
    estimatedBundleBytes: 0,
    lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
    recentEntries: const <WalletLedgerEntry>[],
    paymentEntries: const <WalletLedgerEntry>[],
    rewardEntries: const <WalletLedgerEntry>[],
    logEntries: const <WalletLedgerEntry>[],
  );
}
