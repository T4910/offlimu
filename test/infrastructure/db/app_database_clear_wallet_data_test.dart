import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart' as ledger;
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';
import 'package:offlimu/infrastructure/db/drift_wallet_repository.dart';

void main() {
  test(
    'clearAllUserData removes wallet ledger rows and bundle records',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final walletRepository = DriftWalletRepository(db);
      final bundleRepository = DriftBundleRepository(
        db,
        localNodeId: 'node-local-001',
      );

      await walletRepository.appendEntry(
        ledger.WalletLedgerEntry(
          entryId: 'wallet-grant-1',
          kind: ledger.WalletLedgerEventKind.gatewayReward,
          title: 'Debugger Grant',
          subtitle: 'Before reset',
          amountMinorUnits: 5000,
          balanceImpactMinorUnits: 5000,
          status: ledger.WalletLedgerStatus.confirmed,
          createdAt: DateTime.fromMillisecondsSinceEpoch(1700018000000),
        ),
      );

      await bundleRepository.save(
        Bundle(
          bundleId: 'wallet-reward-1',
          type: Bundle.typeWalletReward,
          sourceNodeId: 'node-local-001',
          destinationNodeId: 'node-local-001',
          payload:
              '{"kind":"reward","rewardKind":"relay","amountMinorUnits":5000,"createdAtMs":1700018000000}',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1700018000000),
          ttlSeconds: 3600,
          signature: 'signed-by-node-local-001',
        ),
      );

      await db.clearAllUserData();

      final walletRows = await db.select(db.walletLedgerEntries).get();
      final bundleRows = await db.select(db.bundleRecords).get();

      expect(walletRows, isEmpty);
      expect(bundleRows, isEmpty);
    },
  );
}
