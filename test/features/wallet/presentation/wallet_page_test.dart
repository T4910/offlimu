import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/node_identity.dart';
import 'package:offlimu/features/wallet/presentation/wallet_page.dart';

void main() {
  Widget buildWalletPage(WalletSection section) {
    return ProviderScope(
      overrides: <Override>[
        localNodeIdentityProvider.overrideWithValue(
          const NodeIdentity(
            nodeId: 'node-local-001',
            displayName: 'OffLiMU Node',
          ),
        ),
      ],
      child: MaterialApp(
        home: WalletPage(section: section),
      ),
    );
  }

  testWidgets('wallet overview renders hero and action tiles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildWalletPage(WalletSection.overview));
    await tester.pumpAndSettle();

    expect(find.text('1,420.50 DTN'), findsOneWidget);
    expect(find.text('PAY'), findsAtLeastNWidgets(2));
    expect(find.text('MY ID'), findsAtLeastNWidgets(2));
    expect(find.text('RECENT LOGS'), findsOneWidget);
  });

  testWidgets('wallet payment page renders transfer flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildWalletPage(WalletSection.pay));
    await tester.pumpAndSettle();

    expect(find.text('OFFLINE TRANSFER'), findsOneWidget);
    expect(find.text('SIGN & PROPAGATE'), findsOneWidget);
    expect(find.text('PRE-FLIGHT AUDIT'), findsOneWidget);
  });

  testWidgets('wallet rewards page renders incentive metrics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildWalletPage(WalletSection.rewards));
    await tester.pumpAndSettle();

    expect(find.text('INCENTIVE EARNINGS'), findsOneWidget);
    expect(find.text('TOTAL RELAY REWARDS'), findsOneWidget);
    expect(find.text('PENDING REWARDS'), findsOneWidget);
  });

  testWidgets('wallet identity page renders node id card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildWalletPage(WalletSection.identity));
    await tester.pumpAndSettle();

    expect(find.text('MY NODE IDENTITY'), findsOneWidget);
    expect(find.text('node-local-001'), findsWidgets);
    expect(find.text('Copy ID'), findsOneWidget);
  });
}