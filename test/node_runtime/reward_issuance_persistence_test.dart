import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/use_cases/reward_issuance_use_case.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';
import 'package:offlimu/infrastructure/db/drift_wallet_repository.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart';

class _PassThroughSignatureService implements BundleSignatureService {
  @override
  Future<Bundle> sign({required Bundle bundle, required String nodeId}) async {
    return bundle.copyWith(signature: 'signed-by-$nodeId');
  }

  @override
  Future<bool> verify(Bundle bundle) async => true;
}

void main() {
  test(
    'reward issuance persists pending bundle and pending ledger entry',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final walletRepository = DriftWalletRepository(db);
      final bundleRepository = DriftBundleRepository(
        db,
        localNodeId: 'node-local-001',
      );
      final signatureService = _PassThroughSignatureService();

      final issuance = RewardIssuanceUseCase(
        bundleRepository: bundleRepository,
        walletRepository: walletRepository,
        bundleSignatureService: signatureService,
      );

      await issuance.createPendingReward(
        localNodeId: 'node-local-001',
        amountMinorUnits: 250,
        rewardKind: 'relay',
        memo: 'test issuance',
      );

      final pending = await bundleRepository.getPendingBundles();
      expect(pending.any((b) => b.type == Bundle.typeWalletReward), isTrue);

      final dashboard = await walletRepository.watchDashboard().first;
      expect(dashboard.pendingRewardMinorUnits >= 250, isTrue);
      expect(
        dashboard.rewardEntries.any(
          (e) =>
              e.status == WalletLedgerStatus.pending ||
              e.amountMinorUnits == 250,
        ),
        isTrue,
      );
    },
  );
}
