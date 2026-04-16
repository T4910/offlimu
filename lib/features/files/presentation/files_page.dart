import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';

class FilesPage extends ConsumerWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataAsync = ref.watch(recentContentMetadataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Files')),
      body: metadataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (List<ContentMetadataRecord> records) {
          if (records.isEmpty) {
            return const Center(child: Text('No stored files yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  title: Text(record.contentHash),
                  subtitle: Text(
                    'size: ${record.totalBytes} bytes • '
                    'chunks: ${record.chunkCount} • '
                    'mime: ${record.mimeType ?? '(unknown)'}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
