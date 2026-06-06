import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart' as ledger;
import 'package:offlimu/domain/entities/node_identity.dart';
import 'package:offlimu/domain/repositories/wallet_repository.dart';
import 'package:offlimu/features/wallet/presentation/wallet_page.dart';

class _FakeWalletRepository implements WalletRepository {
  _FakeWalletRepository({ledger.WalletLedgerDashboard? dashboard})
    : dashboard = dashboard ?? _emptyDashboard;

  static final ledger.WalletLedgerDashboard _emptyDashboard =
      ledger.WalletLedgerDashboard(
        balanceMinorUnits: 0,
        availableBalanceMinorUnits: 0,
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
        recentEntries: const <ledger.WalletLedgerEntry>[],
        paymentEntries: const <ledger.WalletLedgerEntry>[],
        rewardEntries: const <ledger.WalletLedgerEntry>[],
        logEntries: const <ledger.WalletLedgerEntry>[],
      );

  final ledger.WalletLedgerDashboard dashboard;

  @override
  Future<void> appendEntry(ledger.WalletLedgerEntry entry) async {}

  @override
  Stream<ledger.WalletLedgerDashboard> watchDashboard({
    int recentLimit = 3,
    int rewardLimit = 4,
    int logLimit = 6,
  }) async* {
    yield dashboard;
  }
}

void main() {
  Widget buildWalletPage(WalletSection section, WalletRepository repo) {
    return ProviderScope(
      overrides: <Override>[
        localNodeIdentityProvider.overrideWithValue(
          const NodeIdentity(
            nodeId: 'node-local-001',
            displayName: 'OffLiMU Node',
          ),
        ),
        walletRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(home: WalletPage(section: section)),
    );
  }

  testWidgets('wallet overview renders hero and action tiles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildWalletPage(WalletSection.overview, _FakeWalletRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('0.00 DTN'), findsWidgets);
    expect(find.text('LOCAL BALANCE'), findsAtLeastNWidgets(1));
    expect(find.text('AVAILABLE BALANCE'), findsOneWidget);
    expect(find.text('PAY'), findsAtLeastNWidgets(2));
    expect(find.text('MY ID'), findsAtLeastNWidgets(2));
    expect(find.text('RECENT LEDGER'), findsOneWidget);
    expect(find.text('REWARD SNAPSHOT'), findsOneWidget);
    expect(find.text('RELAY REWARDS'), findsOneWidget);
  });

  testWidgets('wallet payment page renders transfer flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildWalletPage(WalletSection.pay, _FakeWalletRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('OFFLINE TRANSFER'), findsOneWidget);
    expect(find.text('SIGN & PROPAGATE'), findsOneWidget);
    expect(find.text('PRE-FLIGHT AUDIT'), findsOneWidget);
    expect(find.text('Back to Home'), findsNothing);
  });

  testWidgets('wallet rewards page renders incentive metrics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildWalletPage(WalletSection.rewards, _FakeWalletRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('REWARD EARNINGS'), findsOneWidget);
    expect(find.text('TOTAL RELAY REWARDS'), findsOneWidget);
    expect(find.text('PENDING REWARDS'), findsOneWidget);
    expect(find.text('REWARD LEDGER'), findsOneWidget);
  });

  testWidgets('wallet identity page renders node id card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildWalletPage(WalletSection.identity, _FakeWalletRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('MY NODE IDENTITY'), findsOneWidget);
    expect(find.text('node-local-001'), findsWidgets);
    expect(find.text('Copy ID'), findsOneWidget);
  });

  testWidgets('wallet log filter pills switch visible entries', (
    WidgetTester tester,
  ) async {
    final spend = ledger.WalletLedgerEntry(
      entryId: 'spend-1',
      kind: ledger.WalletLedgerEventKind.spend,
      title: 'Spend',
      subtitle: 'Payment',
      amountMinorUnits: -500,
      balanceImpactMinorUnits: 0,
      status: ledger.WalletLedgerStatus.pending,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    final reward = ledger.WalletLedgerEntry(
      entryId: 'reward-1',
      kind: ledger.WalletLedgerEventKind.relayReward,
      title: 'Relay Reward',
      subtitle: 'Participation',
      amountMinorUnits: 200,
      balanceImpactMinorUnits: 200,
      status: ledger.WalletLedgerStatus.confirmed,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700001000000),
    );
    final dashboard = ledger.WalletLedgerDashboard(
      balanceMinorUnits: 200,
      availableBalanceMinorUnits: 200,
      relayRewardsMinorUnits: 200,
      gatewayRewardsMinorUnits: 0,
      rewardTotalMinorUnits: 200,
      pendingRewardMinorUnits: 0,
      pendingSpendCount: 1,
      pendingSpendMinorUnits: 500,
      trustScore: 0.3,
      participationGrade: 'D',
      estimatedBundleBytes: 928,
      lastUpdated: reward.createdAt,
      recentEntries: <ledger.WalletLedgerEntry>[reward, spend],
      paymentEntries: <ledger.WalletLedgerEntry>[spend],
      rewardEntries: <ledger.WalletLedgerEntry>[reward],
      logEntries: <ledger.WalletLedgerEntry>[reward, spend],
    );

    await tester.pumpWidget(
      buildWalletPage(
        WalletSection.logs,
        _FakeWalletRepository(dashboard: dashboard),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spend'), findsOneWidget);
    expect(find.text('Relay Reward'), findsOneWidget);

    await tester.tap(find.text('Rewards'));
    await tester.pumpAndSettle();

    expect(find.text('Spend'), findsNothing);
    expect(find.text('Relay Reward'), findsOneWidget);

    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();

    expect(find.text('Spend'), findsOneWidget);
    expect(find.text('Relay Reward'), findsNothing);
  });
}
