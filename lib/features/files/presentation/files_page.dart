import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/file_transfer_explorer_item.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/shared/widgets/subtle_retry_button.dart';

enum _FilesView { explorer, details }

class FilesPage extends ConsumerStatefulWidget {
  const FilesPage({super.key});

  @override
  ConsumerState<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends ConsumerState<FilesPage> {
  static const int _maxAttachmentBytes = 10 * 1024 * 1024;
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
    'mov': 'video/quicktime',
    'zip': 'application/zip',
  };

  bool _isSending = false;
  _FilesView _activeView = _FilesView.explorer;
  String? _sendingName;
  int _sendingProcessedChunks = 0;
  int _sendingTotalChunks = 0;

  @override
  Widget build(BuildContext context) {
    final explorerAsync = ref.watch(fileTransferExplorerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Send file',
            onPressed: _isSending ? null : () => _startSendFlow(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSending ? null : () => _startSendFlow(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SegmentedButton<_FilesView>(
              segments: const <ButtonSegment<_FilesView>>[
                ButtonSegment<_FilesView>(
                  value: _FilesView.explorer,
                  icon: Icon(Icons.folder_copy_rounded),
                  label: Text('Explorer'),
                ),
                ButtonSegment<_FilesView>(
                  value: _FilesView.details,
                  icon: Icon(Icons.route_rounded),
                  label: Text('Transfer Details'),
                ),
              ],
              selected: <_FilesView>{_activeView},
              onSelectionChanged: (selection) {
                setState(() => _activeView = selection.single);
              },
            ),
          ),
          if (_isSending)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _TransferProgressBanner(
                fileName: _sendingName,
                processedChunks: _sendingProcessedChunks,
                totalChunks: _sendingTotalChunks,
              ),
            ),
          Expanded(
            child: explorerAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No stored files yet.'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(fileTransferExplorerProvider);
                  },
                  child: _activeView == _FilesView.explorer
                      ? _FileExplorerList(
                          items: items,
                          onTap: (item) => _showTransferDetails(context, item),
                          onResend: _resendFileTransfer,
                        )
                      : _TransferDetailsList(
                          items: items,
                          onResend: _resendFileTransfer,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSendFlow(BuildContext context) async {
    final destinationNodeId = await _chooseDestination(context);
    if (!context.mounted) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file bytes.')),
      );
      return;
    }

    if (file.size > _maxAttachmentBytes) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File too large (max 10 MB).')),
      );
      return;
    }

    final mimeType = _resolveMimeType(file);
    if (mimeType == null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unsupported file type for MVP transfer.'),
        ),
      );
      return;
    }

    final localNodeId = ref.read(localNodeIdentityProvider).nodeId;
    if (mounted) {
      setState(() {
        _isSending = true;
        _sendingName = file.name;
        _sendingProcessedChunks = 0;
        _sendingTotalChunks = 0;
      });
    }

    try {
      final dispatchResult = await ref
          .read(sendFileTransferUseCaseProvider)
          .send(
            localNodeId: localNodeId,
            destinationNodeId: destinationNodeId,
            fileName: file.name,
            bytes: Uint8List.fromList(bytes),
            mimeType: mimeType,
            onProgress: (progress) {
              if (!mounted) {
                return;
              }
              setState(() {
                _sendingProcessedChunks = progress.processedChunks;
                _sendingTotalChunks = progress.totalChunks;
              });
            },
          );

      if (!context.mounted) {
        return;
      }

      setState(() {
        _isSending = false;
        _sendingName = null;
        _sendingProcessedChunks = 0;
        _sendingTotalChunks = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            destinationNodeId == null
                ? 'Broadcast ${file.name} as ${dispatchResult.chunkCount} chunks'
                : 'Queued ${file.name} to $destinationNodeId as ${dispatchResult.chunkCount} chunks',
          ),
        ),
      );
    } on ContentStoreQuotaExceededException catch (_) {
      if (!context.mounted) {
        return;
      }
      setState(() {
        _isSending = false;
        _sendingName = null;
        _sendingProcessedChunks = 0;
        _sendingTotalChunks = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage quota reached for file cache.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      setState(() {
        _isSending = false;
        _sendingName = null;
        _sendingProcessedChunks = 0;
        _sendingTotalChunks = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to queue file transfer.')),
      );
    }
  }

  Future<String?> _chooseDestination(BuildContext context) async {
    final peers = await ref.read(peerContactsProvider.future);
    if (!context.mounted) {
      return null;
    }

    final peerOptions = peers
        .where(
          (peer) => peer.nodeId != ref.read(localNodeIdentityProvider).nodeId,
        )
        .toList(growable: false);

    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        String? selectedPeerNodeId;
        final manualController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Choose destination',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: peerOptions.isEmpty
                        ? null
                        : selectedPeerNodeId,
                    decoration: const InputDecoration(
                      labelText: 'Recent peer',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Broadcast'),
                      ),
                      ...peerOptions.map(
                        (peer) => DropdownMenuItem<String?>(
                          value: peer.nodeId,
                          child: Text(
                            '${peer.nodeId} (${peer.host}:${peer.port})',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() {
                        selectedPeerNodeId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: manualController,
                    decoration: const InputDecoration(
                      labelText: 'Or enter node ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final manualValue = manualController.text.trim();
                            final resolved = manualValue.isNotEmpty
                                ? manualValue
                                : selectedPeerNodeId;
                            Navigator.of(sheetContext).pop(resolved);
                          },
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showTransferDetails(
    BuildContext context,
    FileTransferExplorerItem item,
  ) async {
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.displayName,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Hash: ${item.contentHash}'),
              Text('Destination: ${item.destinationLabel}'),
              Text('Chunks: ${item.chunkSummary}'),
              Text('Size: ${item.totalBytes ?? 0} bytes'),
              if (item.localPath != null) Text('Local path: ${item.localPath}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.receivedChunkIndices
                    .map((index) => Chip(label: Text('chunk $index')))
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _resendFileTransfer(FileTransferExplorerItem item) async {
    final result = await ref
        .read(resendBundleUseCaseProvider)
        .resendFileTransfer(item.contentHash);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.requeuedAny
              ? 'Requeued ${result.requeuedCount} file bundles.'
              : 'No reusable file bundles found.',
        ),
      ),
    );
  }

  String? _resolveMimeType(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    if (extension == null || extension.isEmpty) {
      return null;
    }
    return _mimeByExtension[extension];
  }
}

class _FileTransferCard extends StatelessWidget {
  const _FileTransferCard({
    required this.item,
    required this.onTap,
    required this.onResend,
  });

  final FileTransferExplorerItem item;
  final VoidCallback onTap;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final kindIcon = switch (item.kind) {
      FileTransferKind.pdf => Icons.picture_as_pdf_rounded,
      FileTransferKind.image => Icons.image_rounded,
      FileTransferKind.video => Icons.video_file_rounded,
      FileTransferKind.audio => Icons.audio_file_rounded,
      FileTransferKind.text => Icons.description_rounded,
      FileTransferKind.archive => Icons.folder_zip_rounded,
      FileTransferKind.unknown => Icons.insert_drive_file_rounded,
    };

    final kindLabel = switch (item.kind) {
      FileTransferKind.pdf => 'PDF',
      FileTransferKind.image => 'Image',
      FileTransferKind.video => 'Video',
      FileTransferKind.audio => 'Audio',
      FileTransferKind.text => 'Text',
      FileTransferKind.archive => 'Archive',
      FileTransferKind.unknown => 'File',
    };

    final accent = _statusAccent(item.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(kindIcon, color: accent, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.displayName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(kindLabel),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 6),
                        _TransferStatusChip(item: item),
                        SubtleRetryButton(
                          tooltip: 'Resend file',
                          onPressed: onResend,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.contentHash,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF617361),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To ${item.destinationLabel} • ${item.chunkSummary}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.totalBytes ?? 0} bytes • ${_formatTimestamp(item.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF617361),
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: item.completionFraction,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFDCE6D7),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileExplorerList extends StatelessWidget {
  const _FileExplorerList({
    required this.items,
    required this.onTap,
    required this.onResend,
  });

  final List<FileTransferExplorerItem> items;
  final ValueChanged<FileTransferExplorerItem> onTap;
  final ValueChanged<FileTransferExplorerItem> onResend;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _FileTransferCard(
          item: item,
          onTap: () => onTap(item),
          onResend: () => onResend(item),
        );
      },
    );
  }
}

class _TransferDetailsList extends StatelessWidget {
  const _TransferDetailsList({required this.items, required this.onResend});

  final List<FileTransferExplorerItem> items;
  final ValueChanged<FileTransferExplorerItem> onResend;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _TransferStatusChip(item: item),
                    SubtleRetryButton(
                      tooltip: 'Resend file',
                      onPressed: () => onResend(item),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Source: ${item.sourceNodeId ?? 'Unknown'}'),
                Text('Destination: ${item.destinationLabel}'),
                Text('Chunks: ${item.chunkSummary}'),
                if (item.lastError != null)
                  Text('Last error: ${item.lastError}'),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: item.completionFraction,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFDCE6D7),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _statusAccent(item.status),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.receivedChunkIndices
                      .map((index) => Chip(label: Text('chunk $index')))
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransferStatusChip extends StatelessWidget {
  const _TransferStatusChip({required this.item});

  final FileTransferExplorerItem item;

  @override
  Widget build(BuildContext context) {
    final accent = _statusAccent(item.status);
    return Chip(
      label: Text(item.statusLabel),
      visualDensity: VisualDensity.compact,
      backgroundColor: accent.withValues(alpha: 0.12),
      side: BorderSide(color: accent.withValues(alpha: 0.4)),
      labelStyle: TextStyle(color: accent, fontWeight: FontWeight.w700),
    );
  }
}

Color _statusAccent(FileTransferStatus status) {
  return switch (status) {
    FileTransferStatus.complete => const Color(0xFF2E7D32),
    FileTransferStatus.partial => const Color(0xFF8C6A2B),
    FileTransferStatus.failed => const Color(0xFFB23B32),
  };
}

class _TransferProgressBanner extends StatelessWidget {
  const _TransferProgressBanner({
    required this.fileName,
    required this.processedChunks,
    required this.totalChunks,
  });

  final String? fileName;
  final int processedChunks;
  final int totalChunks;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              fileName == null ? 'Preparing transfer...' : 'Sending $fileName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              minHeight: 4,
              value: totalChunks > 0 ? processedChunks / totalChunks : null,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime timestamp) {
  final year = timestamp.year.toString().padLeft(4, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  final day = timestamp.day.toString().padLeft(2, '0');
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute UTC';
}
