import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/node_identity.dart';
import 'package:offlimu/domain/entities/peer_contact.dart';
import 'package:offlimu/features/node_status/presentation/node_status_page.dart';
import 'package:offlimu/node_runtime/node_runtime_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home hides debug-heavy sections and shows quick actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHome(peers: _peers()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to OffLiMU'), findsOneWidget);
    expect(find.text('Transport and Errors'), findsNothing);
    expect(find.text('ACK History'), findsNothing);
    expect(find.text('Sync History'), findsNothing);
    expect(find.textContaining('ACK Duplicates'), findsNothing);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Web Search'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
  });

  testWidgets('peer history shows connection details and copies peer node id', (
    WidgetTester tester,
  ) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final data = Map<String, Object?>.from(call.arguments as Map);
            copiedText = data['text'] as String?;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(_buildHome(peers: _peers()));
    await tester.pumpAndSettle();

    expect(find.text('Peer History'), findsOneWidget);
    expect(find.text('node-peer-alpha'), findsOneWidget);
    expect(find.textContaining('192.168.1.8:47800'), findsOneWidget);
    expect(find.textContaining('seen 3x'), findsOneWidget);
    expect(find.textContaining('Last connected'), findsAtLeastNWidgets(1));

    final copyButton = find.byTooltip('Copy peer node ID').first;
    await tester.ensureVisible(copyButton);
    await tester.pumpAndSettle();
    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    expect(copiedText, 'node-peer-alpha');
    expect(find.text('Node ID copied'), findsOneWidget);
  });

  testWidgets('peer history empty state is friendly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHome(peers: const <PeerContact>[]));
    await tester.pumpAndSettle();

    expect(
      find.text('No peers yet. Start another OffLiMU node on this network.'),
      findsOneWidget,
    );
  });
}

Widget _buildHome({required List<PeerContact> peers}) {
  return ProviderScope(
    overrides: <Override>[
      nodeRuntimeStateProvider.overrideWithValue(
        AsyncValue<NodeRuntimeState>.data(
          NodeRuntimeState(
            identity: const NodeIdentity(
              nodeId: 'node-local-001',
              displayName: 'OffLiMU Node',
            ),
            health: RuntimeHealth.connected,
            discoveredPeers: peers.length,
            pendingBundles: 2,
            gatewayEnabled: true,
            telemetry: const RuntimeTelemetry(inboundBundlesRelayed: 4),
          ),
        ),
      ),
      peerContactsProvider.overrideWith(
        (ref) => Stream<List<PeerContact>>.value(peers),
      ),
      syncRunStateProvider.overrideWith((ref) => null),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (context, state) => const NodeStatusPage(),
          ),
          GoRoute(path: '/chat', builder: (context, state) => const SizedBox()),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/files',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/queue',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(path: '/sync', builder: (context, state) => const SizedBox()),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/debug',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      ),
    ),
  );
}

List<PeerContact> _peers() {
  final now = DateTime.now();
  return <PeerContact>[
    PeerContact(
      nodeId: 'node-peer-alpha',
      host: '192.168.1.8',
      port: 47800,
      lastSeen: now.subtract(const Duration(seconds: 20)),
      seenCount: 3,
    ),
    PeerContact(
      nodeId: 'node-peer-beta',
      host: '192.168.1.9',
      port: 47801,
      lastSeen: now.subtract(const Duration(hours: 3)),
      seenCount: 1,
    ),
  ];
}
