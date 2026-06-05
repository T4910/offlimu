import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/entities/chat_thread.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('OffLiMU Chat')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/chat/new'),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('New chat'),
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (threads) {
          final broadcastThread = threads
              .where((thread) => thread.kind == ChatThreadKind.broadcast)
              .firstOrNull;
          final directThreads = threads
              .where((thread) => thread.kind == ChatThreadKind.direct)
              .toList(growable: false);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: directThreads.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _BroadcastThreadTile(thread: broadcastThread);
              }

              final thread = directThreads[index - 1];
              return _DirectThreadTile(thread: thread);
            },
          );
        },
      ),
    );
  }
}

class _BroadcastThreadTile extends StatelessWidget {
  const _BroadcastThreadTile({required this.thread});

  final ChatThread? thread;

  @override
  Widget build(BuildContext context) {
    final ChatThread? current = thread;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: const Icon(Icons.campaign_outlined),
        ),
        title: const Text('Broadcast'),
        subtitle: Text(_subtitleFor(current)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              (current?.messageCount ?? 0).toString(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push('/chat/broadcast'),
      ),
    );
  }

  String _subtitleFor(ChatThread? thread) {
    final preview = thread?.lastMessagePreview;
    if (preview == null || preview.isEmpty) {
      return 'Messages sent to all reachable peers';
    }
    return preview;
  }
}

class _DirectThreadTile extends StatelessWidget {
  const _DirectThreadTile({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          child: Text(_initialFor(thread.title)),
        ),
        title: Text(thread.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          _subtitleFor(thread),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              thread.messageCount.toString(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () =>
            context.push('/chat/${Uri.encodeComponent(thread.threadId)}'),
      ),
    );
  }

  String _subtitleFor(ChatThread thread) {
    final preview = thread.lastMessagePreview;
    if (preview == null || preview.isEmpty) {
      return 'No messages yet';
    }

    final status = thread.lastDeliveryStatus;
    if (status == null || status == MessageDeliveryStatus.received) {
      return preview;
    }

    return '${status.name}: $preview';
  }

  String _initialFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.characters.first.toUpperCase();
  }
}
