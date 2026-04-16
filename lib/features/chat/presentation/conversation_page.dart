import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/chat_message.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({required this.peerNodeId, super.key});

  final String peerNodeId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  static const int _messagePageSize = 50;

  final TextEditingController _composerController = TextEditingController();
  int _messagesLimit = _messagePageSize;

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localIdentity = ref.watch(localNodeIdentityProvider);
    final chatMessagesAsync = ref.watch(
      chatMessagesByLimitProvider(_messagesLimit),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Conversation: ${widget.peerNodeId}')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: chatMessagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
              data: (messages) {
                final List<ChatMessage> conversation = messages
                    .where((message) {
                      final String? peerForMessage = message.isOutgoing
                          ? message.destinationNodeId
                          : message.sourceNodeId;
                      return peerForMessage == widget.peerNodeId;
                    })
                    .toList(growable: false);
                final bool hasMore = messages.length >= _messagesLimit;

                if (conversation.isEmpty) {
                  return Center(
                    child: Text('No messages with ${widget.peerNodeId} yet.'),
                  );
                }

                return Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView.separated(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: conversation.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final ChatMessage message = conversation[index];
                          final bool mine = message.isOutgoing;

                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Card(
                                margin: EdgeInsets.zero,
                                color: mine
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHigh,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(message.body),
                                      const SizedBox(height: 6),
                                      Text(
                                        _statusText(message),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _messagesLimit += _messagePageSize;
                            });
                          },
                          child: const Text('Load older messages'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _composerController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _sendMessage(
                    localNodeId: localIdentity.nodeId,
                    destinationNodeId: widget.peerNodeId,
                  ),
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage({
    required String localNodeId,
    required String destinationNodeId,
  }) async {
    final String text = _composerController.text.trim();
    if (text.isEmpty) {
      return;
    }

    await ref
        .read(sendChatMessageUseCaseProvider)
        .send(
          localNodeId: localNodeId,
          destinationNodeId: destinationNodeId,
          body: text,
        );
    _composerController.clear();
  }

  String _statusText(ChatMessage message) {
    if (!message.isOutgoing) {
      return 'received from ${message.sourceNodeId}';
    }

    switch (message.deliveryStatus) {
      case MessageDeliveryStatus.pending:
        return 'pending';
      case MessageDeliveryStatus.sent:
        return 'sent';
      case MessageDeliveryStatus.acked:
        return 'acked';
      case MessageDeliveryStatus.failed:
        return 'failed (${message.failedAttempts})';
      case MessageDeliveryStatus.received:
        return 'received';
    }
  }
}
