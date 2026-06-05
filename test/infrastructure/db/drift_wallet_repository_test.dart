import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart' as ledger;
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_wallet_repository.dart';

void main() {
  group('DriftWalletRepository', () {
    test('starts empty until a manual grant is added', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final repository = DriftWalletRepository(db);
      final dashboard = await repository.watchDashboard().first;

      expect(dashboard.balanceMinorUnits, 0);
      expect(dashboard.availableBalanceMinorUnits, 0);
      expect(dashboard.rewardEntries, isEmpty);
      expect(dashboard.recentEntries, isEmpty);
      expect(dashboard.pendingSpendCount, 0);
      expect(dashboard.logEntries, isEmpty);
    });

    test(
      'persists a manual grant and a pending spend without changing the grant balance',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        final repository = DriftWalletRepository(db);
        await repository.appendEntry(
          ledger.WalletLedgerEntry(
            entryId: 'debug-grant-1',
            kind: ledger.WalletLedgerEventKind.gatewayReward,
            title: 'Debugger Grant',
            subtitle: 'Manual coin grant',
            amountMinorUnits: 5000,
            balanceImpactMinorUnits: 5000,
            status: ledger.WalletLedgerStatus.confirmed,
            createdAt: DateTime.fromMillisecondsSinceEpoch(1700017000000),
          ),
        );
        await repository.appendEntry(
          ledger.WalletLedgerEntry(
            entryId: 'pending-test-spend',
            kind: ledger.WalletLedgerEventKind.spend,
            title: 'Pending Spend',
            subtitle: 'Awaiting reconciliation',
            amountMinorUnits: -2500,
            balanceImpactMinorUnits: 0,
            status: ledger.WalletLedgerStatus.pending,
            createdAt: DateTime.fromMillisecondsSinceEpoch(1700018000000),
            counterpartyNodeId: 'node-test',
          ),
        );

        final dashboard = await repository.watchDashboard().first;

        expect(dashboard.balanceMinorUnits, 5000);
        expect(dashboard.availableBalanceMinorUnits, 2500);
        expect(dashboard.pendingSpendCount, 1);
        expect(dashboard.rewardEntries, hasLength(1));
        expect(
          dashboard.paymentEntries.any(
            (entry) => entry.entryId == 'pending-test-spend',
          ),
          isTrue,
        );
      },
    );

    test(
      'resolved rejected spend restores available balance without changing local balance',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        final repository = DriftWalletRepository(db);
        await repository.appendEntry(
          ledger.WalletLedgerEntry(
            entryId: 'debug-grant-1',
            kind: ledger.WalletLedgerEventKind.gatewayReward,
            title: 'Debugger Grant',
            subtitle: 'Manual coin grant',
            amountMinorUnits: 5000,
            balanceImpactMinorUnits: 5000,
            status: ledger.WalletLedgerStatus.confirmed,
            createdAt: DateTime.fromMillisecondsSinceEpoch(1700017000000),
          ),
        );
        await repository.appendEntry(
          ledger.WalletLedgerEntry(
            entryId: 'pending-test-spend',
            kind: ledger.WalletLedgerEventKind.spend,
            title: 'Pending Spend',
            subtitle: 'Awaiting reconciliation',
            amountMinorUnits: -3000,
            balanceImpactMinorUnits: 0,
            status: ledger.WalletLedgerStatus.pending,
            createdAt: DateTime.fromMillisecondsSinceEpoch(1700018000000),
            counterpartyNodeId: 'node-test',
            sourceBundleId: 'wallet-spend-1',
          ),
        );
        await repository.appendEntry(
          ledger.WalletLedgerEntry(
            entryId: 'wallet-spend-expired-wallet-spend-1',
            kind: ledger.WalletLedgerEventKind.rejection,
            title: 'Spend Timeframe Exceeded',
            subtitle: 'TTL exceeded',
            amountMinorUnits: 3000,
            balanceImpactMinorUnits: 0,
            status: ledger.WalletLedgerStatus.rejected,
            createdAt: DateTime.fromMillisecondsSinceEpoch(1700020000000),
            counterpartyNodeId: 'node-test',
            sourceBundleId: 'wallet-spend-1',
          ),
        );

        final dashboard = await repository.watchDashboard().first;

        expect(dashboard.balanceMinorUnits, 5000);
        expect(dashboard.availableBalanceMinorUnits, 5000);
        expect(dashboard.pendingSpendCount, 0);
        expect(dashboard.pendingSpendMinorUnits, 0);
      },
    );
  });
}
