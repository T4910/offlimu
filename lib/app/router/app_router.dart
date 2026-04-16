import 'package:go_router/go_router.dart';
import 'package:offlimu/features/bundle_queue/presentation/bundle_queue_page.dart';
import 'package:offlimu/features/chat/presentation/chat_page.dart';
import 'package:offlimu/features/chat/presentation/conversation_page.dart';
import 'package:offlimu/features/files/presentation/files_page.dart';
import 'package:offlimu/features/node_status/presentation/node_status_page.dart';
import 'package:offlimu/features/settings/presentation/settings_page.dart';
import 'package:offlimu/features/sync/presentation/sync_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const NodeStatusPage()),
    GoRoute(
      path: '/status',
      builder: (context, state) => const NodeStatusPage(),
    ),
    GoRoute(
      path: '/queue',
      builder: (context, state) => const BundleQueuePage(),
    ),
    GoRoute(path: '/chat', builder: (context, state) => const ChatPage()),
    GoRoute(
      path: '/chat/:peerNodeId',
      builder: (context, state) {
        final String peerNodeId = state.pathParameters['peerNodeId'] ?? '';
        return ConversationPage(peerNodeId: peerNodeId);
      },
    ),
    GoRoute(path: '/files', builder: (context, state) => const FilesPage()),
    GoRoute(path: '/sync', builder: (context, state) => const SyncPage()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
