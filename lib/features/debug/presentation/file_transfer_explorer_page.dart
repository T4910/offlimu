import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/file_transfer_explorer_item.dart';

class FileTransferExplorerPage extends ConsumerWidget {
  const FileTransferExplorerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerAsync = ref.watch(fileTransferExplorerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('File Transfer Explorer')),
      body: explorerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (items) {
          final total = items.length;
          final complete = items.where((item) => item.isComplete).length;
          final incomplete = total - complete;
          final totalChunks = items.fold<int>(0, (sum, item) => sum + item.availableChunkCount);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _MetricChip(label: 'Transfers', value: total.toString()),
                      _MetricChip(label: 'Complete', value: complete.toString()),
                      _MetricChip(label: 'Incomplete', value: incomplete.toString()),
                      _MetricChip(label: 'Chunks', value: totalChunks.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No file transfers recorded yet.'),
                  ),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExplorerCard(item: item),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ExplorerCard extends StatelessWidget {
  const _ExplorerCard({required this.item});

  final FileTransferExplorerItem item;

  @override
  Widget build(BuildContext context) {
    final kindLabel = switch (item.kind) {
      FileTransferKind.pdf => 'PDF',
      FileTransferKind.image => 'Image',
      FileTransferKind.video => 'Video',
      FileTransferKind.audio => 'Audio',
      FileTransferKind.text => 'Text',
      FileTransferKind.archive => 'Archive',
      FileTransferKind.unknown => 'Unknown',
    };

    return Card(
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
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(label: Text(kindLabel), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 8),
            Text('Hash: ${item.contentHash}'),
            Text('Destination: ${item.destinationLabel}'),
            Text('Status: ${item.chunkSummary}'),
            Text('Size: ${item.totalBytes ?? 0} bytes'),
            Text('Created: ${_formatTimestamp(item.createdAt)}'),
            if (item.localPath != null) Text('Local path: ${item.localPath}'),
            const SizedBox(height: 12),
            Text(
              'Chunk map',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.receivedChunkIndices
                  .map((index) => Chip(label: Text('#$index')))
                  .toList(growable: false),
            ),
            const SizedBox(height: 10),
            Text('Metadata bundle: ${item.metadataBundleId ?? '(none)'}'),
            if (item.chunkBundleIdsByIndex.isNotEmpty)
              Text('Chunk bundles: ${item.chunkBundleIdsByIndex.values.join(', ')}'),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: item.completionFraction,
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'), visualDensity: VisualDensity.compact);
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
