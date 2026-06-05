import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/services/content_store.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({required this.peerNodeId, super.key})
    : isBroadcast = false;

  const ConversationPage.broadcast({super.key})
    : peerNodeId = null,
      isBroadcast = true;

  final String? peerNodeId;
  final bool isBroadcast;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  static const int _maxAttachmentBytes = 10 * 1024 * 1024;
  static const int _messagePageSize = 50;
  static const Map<String, String> _mimeByExtension = <String, String>{
    'txt': 'text/plain',
    'md': 'text/markdown',
    'json': 'application/json',
    'csv': 'text/csv',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'pdf': 'application/pdf',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'mp4': 'video/mp4',
  };

  final TextEditingController _composerController = TextEditingController();
  int _messagesLimit = _messagePageSize;
  bool _isTransferInProgress = false;
  String? _transferFileName;
  int _transferProcessedChunks = 0;
  int _transferTotalChunks = 0;

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localIdentity = ref.watch(localNodeIdentityProvider);
    final messagesAsync = widget.isBroadcast
        ? ref.watch(broadcastChatMessagesProvider(_messagesLimit))
        : ref.watch(
            conversationMessagesProvider(
              ConversationMessagesRequest(
                peerNodeId: widget.peerNodeId!,
                limit: _messagesLimit,
              ),
            ),
          );

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
              data: (messages) {
                final bool hasMore = messages.length >= _messagesLimit;

                if (messages.isEmpty) {
                  return Center(child: Text(_emptyMessage));
                }

                return Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView.separated(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final ChatMessage message = messages[index];
                          return _MessageBubble(message: message);
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
          if (_isTransferInProgress)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _transferFileName == null
                        ? 'Preparing transfer...'
                        : 'Queuing $_transferFileName ($_transferProcessedChunks/$_transferTotalChunks)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    minHeight: 4,
                    value: _transferTotalChunks > 0
                        ? _transferProcessedChunks / _transferTotalChunks
                        : null,
                  ),
                ],
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
                      hintText: 'Type an offline message...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Attach file',
                  onPressed: _isTransferInProgress
                      ? null
                      : () => _sendFileAttachment(
                          localNodeId: localIdentity.nodeId,
                          destinationNodeId: _destinationNodeId,
                        ),
                  icon: const Icon(Icons.attach_file),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isTransferInProgress
                      ? null
                      : () => _sendMessage(
                          localNodeId: localIdentity.nodeId,
                          destinationNodeId: _destinationNodeId,
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

  String get _title {
    if (widget.isBroadcast) {
      return 'Broadcast';
    }
    return 'Conversation: ${widget.peerNodeId}';
  }

  String get _emptyMessage {
    if (widget.isBroadcast) {
      return 'No broadcast messages yet.';
    }
    return 'No messages with ${widget.peerNodeId} yet.';
  }

  String? get _destinationNodeId =>
      widget.isBroadcast ? null : widget.peerNodeId;

  Future<void> _sendMessage({
    required String localNodeId,
    required String? destinationNodeId,
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

  Future<void> _sendFileAttachment({
    required String localNodeId,
    required String? destinationNodeId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final PlatformFile file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file bytes.')),
      );
      return;
    }

    if (file.size > _maxAttachmentBytes) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File too large (max 10 MB).')),
      );
      return;
    }

    final String? mimeType = _resolveMimeType(file);
    if (mimeType == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unsupported file type for MVP transfer.'),
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isTransferInProgress = true;
        _transferFileName = file.name;
        _transferProcessedChunks = 0;
        _transferTotalChunks = 0;
      });
    }

    try {
      final dispatchResult = await ref
          .read(sendFileTransferUseCaseProvider)
          .send(
            localNodeId: localNodeId,
            destinationNodeId: destinationNodeId,
            fileName: file.name,
            bytes: bytes,
            mimeType: mimeType,
            onProgress: (progress) {
              if (!mounted) {
                return;
              }
              setState(() {
                _transferProcessedChunks = progress.processedChunks;
                _transferTotalChunks = progress.totalChunks;
              });
            },
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _isTransferInProgress = false;
        _transferFileName = null;
        _transferProcessedChunks = 0;
        _transferTotalChunks = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Queued ${file.name} as ${dispatchResult.chunkCount} chunks',
          ),
        ),
      );
    } on ContentStoreQuotaExceededException {
      if (!mounted) {
        return;
      }

      _resetTransferProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage quota reached for file cache.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _resetTransferProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to queue file transfer.')),
      );
    }
  }

  void _resetTransferProgress() {
    setState(() {
      _isTransferInProgress = false;
      _transferFileName = null;
      _transferProcessedChunks = 0;
      _transferTotalChunks = 0;
    });
  }

  String? _resolveMimeType(PlatformFile file) {
    final String? extension = file.extension?.toLowerCase();
    if (extension == null || extension.isEmpty) {
      return null;
    }
    return _mimeByExtension[extension];
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.isOutgoing;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Card(
          margin: EdgeInsets.zero,
          color: mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(message.body),
                const SizedBox(height: 6),
                Text(
                  _statusText(message),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
