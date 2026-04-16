import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/services/content_store.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
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
  String? _selectedDestinationNodeId;
  bool _isTransferInProgress = false;
  String? _transferFileName;
  int _transferProcessedChunks = 0;
  int _transferTotalChunks = 0;
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
    final peersAsync = ref.watch(peerContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('OffLiMU Chat')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: chatMessagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Send one while runtime is active.',
                    ),
                  );
                }
                final bool hasMore = messages.length >= _messagesLimit;

                return Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView.separated(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final bool mine = message.isOutgoing;
                          final String? peerNodeId = mine
                              ? message.destinationNodeId
                              : message.sourceNodeId;

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
                                child: InkWell(
                                  onTap: peerNodeId == null
                                      ? null
                                      : () => context.push('/chat/$peerNodeId'),
                                  borderRadius: BorderRadius.circular(12),
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
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: peersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (peers) {
                final options = peers
                    .where((peer) => peer.nodeId != localIdentity.nodeId)
                    .take(20)
                    .toList(growable: false);

                if (options.isEmpty) {
                  return const Text(
                    'Destination: Broadcast (no specific peer selected)',
                  );
                }

                final selected =
                    options.any(
                      (peer) => peer.nodeId == _selectedDestinationNodeId,
                    )
                    ? _selectedDestinationNodeId
                    : null;

                return DropdownButtonFormField<String?>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Broadcast / Any Peer'),
                    ),
                    ...options.map(
                      (peer) => DropdownMenuItem<String?>(
                        value: peer.nodeId,
                        child: Text(
                          '${peer.nodeId} (${peer.host}:${peer.port})',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDestinationNodeId = value;
                    });
                  },
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
                          destinationNodeId: _selectedDestinationNodeId,
                        ),
                  icon: const Icon(Icons.attach_file),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isTransferInProgress
                      ? null
                      : () => _sendMessage(
                          localNodeId: localIdentity.nodeId,
                          destinationNodeId: _selectedDestinationNodeId,
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
    } on ContentStoreQuotaExceededException catch (_) {
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
        const SnackBar(content: Text('Storage quota reached for file cache.')),
      );
    } catch (_) {
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
        const SnackBar(content: Text('Failed to queue file transfer.')),
      );
    }
  }

  String? _resolveMimeType(PlatformFile file) {
    final String? extension = file.extension?.toLowerCase();
    if (extension == null || extension.isEmpty) {
      return null;
    }
    return _mimeByExtension[extension];
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
