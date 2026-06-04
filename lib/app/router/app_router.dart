import 'package:go_router/go_router.dart';
import 'package:offlimu/features/bundle_queue/presentation/bundle_queue_page.dart';
import 'package:offlimu/features/debug/presentation/debug_page.dart';
import 'package:offlimu/features/debug/presentation/bundle_explorer_page.dart';
import 'package:offlimu/features/debug/presentation/file_transfer_explorer_page.dart';
import 'package:offlimu/features/chat/presentation/chat_page.dart';
import 'package:offlimu/features/chat/presentation/conversation_page.dart';
import 'package:offlimu/features/files/presentation/files_page.dart';
import 'package:offlimu/features/node_status/presentation/node_status_page.dart';
import 'package:offlimu/features/wallet/presentation/wallet_page.dart';
import 'package:offlimu/features/settings/presentation/settings_page.dart';
import 'package:offlimu/features/sync/presentation/sync_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const NodeStatusPage()),
    GoRoute(path: '/debug', builder: (context, state) => const DebugPage()),
    GoRoute(
      path: '/debug/bundles',
      builder: (context, state) => const BundleExplorerPage(),
    ),
    GoRoute(
      path: '/debug/files',
      builder: (context, state) => const FileTransferExplorerPage(),
    ),
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
      path: '/wallet',
      builder: (context, state) => const WalletPage(),
      routes: <RouteBase>[
        GoRoute(
          path: 'pay',
          builder: (context, state) => const WalletPage(section: WalletSection.pay),
        ),
        GoRoute(
          path: 'logs',
          builder: (context, state) => const WalletPage(section: WalletSection.logs),
        ),
        GoRoute(
          path: 'rewards',
          builder: (context, state) => const WalletPage(section: WalletSection.rewards),
        ),
        GoRoute(
          path: 'id',
          builder: (context, state) => const WalletPage(section: WalletSection.identity),
        ),
      ],
    ),
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
