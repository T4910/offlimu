import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/entities/chat_thread.dart';
import 'package:offlimu/domain/entities/file_transfer_explorer_item.dart';
import 'package:offlimu/domain/entities/node_identity.dart';
import 'package:offlimu/domain/entities/peer_contact.dart';
import 'package:offlimu/features/chat/presentation/chat_page.dart';
import 'package:offlimu/features/chat/presentation/conversation_page.dart';
import 'package:offlimu/features/chat/presentation/new_chat_page.dart';

void main() {
  testWidgets('chat landing page shows broadcast tile and peer thread', (
    tester,
  ) async {
    final router = _buildRouter(initialLocation: '/chat');

    await tester.pumpWidget(
      _buildApp(
        router: router,
        overrides: <Override>[
          chatThreadsProvider.overrideWith(
            (ref) => Stream<List<ChatThread>>.value(<ChatThread>[
              ChatThread(
                threadId: 'node-b',
                kind: ChatThreadKind.direct,
                title: 'node-b',
                lastMessagePreview: 'hello b',
                lastMessageAt: DateTime.fromMillisecondsSinceEpoch(1000),
                messageCount: 2,
                lastDeliveryStatus: MessageDeliveryStatus.sent,
              ),
            ]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Broadcast'), findsOneWidget);
    expect(find.text('node-b'), findsOneWidget);
    expect(find.text('sent: hello b'), findsOneWidget);
  });

  testWidgets('peer thread tile opens direct conversation route', (
    tester,
  ) async {
    final router = _buildRouter(initialLocation: '/chat');

    await tester.pumpWidget(
      _buildApp(
        router: router,
        overrides: <Override>[
          chatThreadsProvider.overrideWith(
            (ref) => Stream<List<ChatThread>>.value(<ChatThread>[
              ChatThread(
                threadId: 'node-b',
                kind: ChatThreadKind.direct,
                title: 'node-b',
                lastMessagePreview: 'hello b',
                lastMessageAt: DateTime.fromMillisecondsSinceEpoch(1000),
                messageCount: 1,
              ),
            ]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('node-b'));
    await tester.pumpAndSettle();

    expect(find.text('direct:node-b'), findsOneWidget);
  });

  testWidgets('new chat page supports peer selection and manual node id', (
    tester,
  ) async {
    final router = _buildRouter(initialLocation: '/chat/new');

    await tester.pumpWidget(_buildApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('node-b'), findsOneWidget);

    await tester.tap(find.text('node-b'));
    await tester.pumpAndSettle();
    expect(find.text('direct:node-b'), findsOneWidget);

    router.go('/chat/new');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'node-manual');
    await tester.tap(find.text('Open chat'));
    await tester.pumpAndSettle();

    expect(find.text('direct:node-manual'), findsOneWidget);
  });

  testWidgets('conversation shows file attachment preview in timeline', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          localNodeIdentityProvider.overrideWithValue(
            const NodeIdentity(nodeId: 'node-a', displayName: 'Node A'),
          ),
          conversationMessagesProvider(
            const ConversationMessagesRequest(peerNodeId: 'node-b', limit: 50),
          ).overrideWith(
            (ref) => Stream<List<ChatMessage>>.value(const <ChatMessage>[]),
          ),
          fileTransferExplorerProvider.overrideWithValue(
            AsyncValue.data(<FileTransferExplorerItem>[
              FileTransferExplorerItem(
                contentHash: 'sha256:report',
                fileName: 'report.pdf',
                mimeType: 'application/pdf',
                kind: FileTransferKind.pdf,
                destinationNodeId: 'node-b',
                sourceNodeId: 'node-a',
                createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
                lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(
                  1700000001000,
                ),
                totalBytes: 2048,
                expectedChunkCount: 4,
                chunkBundleIdsByIndex: const <int, String>{
                  0: 'chunk-0',
                  1: 'chunk-1',
                },
                metadataBundleId: 'meta-1',
                localPath: null,
                failedBundleCount: 0,
                lastError: null,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: ConversationPage(peerNodeId: 'node-b')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('partial • 2/4 chunks'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });
}

Widget _buildApp({
  required GoRouter router,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: <Override>[
      localNodeIdentityProvider.overrideWithValue(
        const NodeIdentity(nodeId: 'node-a', displayName: 'Node A'),
      ),
      peerContactsProvider.overrideWith(
        (ref) => Stream<List<PeerContact>>.value(<PeerContact>[
          PeerContact(
            nodeId: 'node-b',
            host: '127.0.0.1',
            port: 47800,
            lastSeen: DateTime.fromMillisecondsSinceEpoch(1000),
          ),
        ]),
      ),
      ...overrides,
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

GoRouter _buildRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(path: '/chat', builder: (context, state) => const ChatPage()),
      GoRoute(
        path: '/chat/new',
        builder: (context, state) => const NewChatPage(),
      ),
      GoRoute(
        path: '/chat/broadcast',
        builder: (context, state) => const Scaffold(body: Text('broadcast')),
      ),
      GoRoute(
        path: '/chat/:peerNodeId',
        builder: (context, state) {
          final peerNodeId = state.pathParameters['peerNodeId'] ?? '';
          return Scaffold(body: Text('direct:$peerNodeId'));
        },
      ),
    ],
  );
}
