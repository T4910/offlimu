import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/use_cases/wallet_event_bundle_mapper.dart';
import 'package:offlimu/domain/use_cases/wallet_sync_reconciliation_service.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_wallet_repository.dart';

void main() {
  test('applyInboundWalletBundle credits recipient on wallet_spend', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final walletRepository = DriftWalletRepository(db);
    final mapper = WalletEventBundleMapper();
    final service = WalletSyncReconciliationService(
      walletRepository: walletRepository,
      mapper: mapper,
      now: () => DateTime.now(),
    );

    final now = DateTime.now();
    final spendBundle = mapper.toSpendBundle(
      bundleId: 'spend-1',
      localNodeId: 'node-remote-123', // sender
      recipientNodeId: 'node-local-001',
      amountMinorUnits: 750,
      createdAt: now,
      memo: 'Test payment',
    );

    await service.applyInboundWalletBundle(spendBundle);

    final dashboard = await walletRepository.watchDashboard().first;
    final matches = dashboard.recentEntries
        .where((e) => e.sourceBundleId == spendBundle.bundleId)
        .toList(growable: false);

    expect(matches, hasLength(1));
    expect(matches.single.amountMinorUnits, 750);
    expect(matches.single.isCredit, isTrue);
  });

  test(
    'applyInboundWalletBundle is idempotent for the same spend bundle',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final walletRepository = DriftWalletRepository(db);
      final mapper = WalletEventBundleMapper();
      final service = WalletSyncReconciliationService(
        walletRepository: walletRepository,
        mapper: mapper,
        now: () => DateTime.now(),
      );

      final now = DateTime.now();
      final spendBundle = mapper.toSpendBundle(
        bundleId: 'spend-2',
        localNodeId: 'node-remote-123',
        recipientNodeId: 'node-local-001',
        amountMinorUnits: 1200,
        createdAt: now,
      );

      await service.applyInboundWalletBundle(spendBundle);
      await service.applyInboundWalletBundle(spendBundle);

      final dashboard = await walletRepository.watchDashboard().first;
      final matches = dashboard.recentEntries
          .where((e) => e.sourceBundleId == spendBundle.bundleId)
          .toList(growable: false);

      expect(matches, hasLength(1));
    },
  );
}
