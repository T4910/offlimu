import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart';
import 'package:offlimu/domain/entities/node_identity.dart';
import 'package:offlimu/features/wallet/presentation/wallet_page.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_wallet_repository.dart';

void main() {
  // A lightweight fake repository for widget tests to avoid opening real DB streams.
  class _FakeWalletRepository implements WalletRepository {
    _FakeWalletRepository();

    final Dashboard = WalletLedgerDashboard(
      balanceMinorUnits: 5000,
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

    @override
    Future<void> appendEntry(WalletLedgerEntry entry) async {}

    @override
    Future<void> seedIfEmpty() async {}

    @override
    Stream<WalletLedgerDashboard> watchDashboard({int recentLimit = 3, int rewardLimit = 4, int logLimit = 6}) async* {
      yield Dashboard;
    }
  }

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
      child: MaterialApp(
        home: WalletPage(section: section),
      ),
    );
  }

  testWidgets('wallet overview renders hero and action tiles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildWalletPage(WalletSection.overview, _FakeWalletRepository()));
    await tester.pumpAndSettle();

    expect(find.text('50.00 DTN'), findsOneWidget);
    expect(find.text('PAY'), findsAtLeastNWidgets(2));
    expect(find.text('MY ID'), findsAtLeastNWidgets(2));
    expect(find.text('RECENT LEDGER'), findsOneWidget);
    expect(find.text('RELAY REWARDS'), findsOneWidget);
  });

  testWidgets('wallet payment page renders transfer flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildWalletPage(WalletSection.pay, _FakeWalletRepository()));
    await tester.pumpAndSettle();

    expect(find.text('OFFLINE TRANSFER'), findsOneWidget);
    expect(find.text('SIGN & PROPAGATE'), findsOneWidget);
    expect(find.text('PRE-FLIGHT AUDIT'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('wallet rewards page renders incentive metrics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildWalletPage(WalletSection.rewards, _FakeWalletRepository()));
    await tester.pumpAndSettle();

    expect(find.text('INCENTIVE EARNINGS'), findsOneWidget);
    expect(find.text('TOTAL RELAY REWARDS'), findsOneWidget);
    expect(find.text('PENDING REWARDS'), findsOneWidget);
    expect(find.text('REWARD LEDGER'), findsOneWidget);
  });

  testWidgets('wallet identity page renders node id card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildWalletPage(WalletSection.identity, _FakeWalletRepository()));
    await tester.pumpAndSettle();

    expect(find.text('MY NODE IDENTITY'), findsOneWidget);
    expect(find.text('node-local-001'), findsWidgets);
    expect(find.text('Copy ID'), findsOneWidget);
  });
}
