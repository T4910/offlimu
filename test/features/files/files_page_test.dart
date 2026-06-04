import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/file_transfer_explorer_item.dart';
import 'package:offlimu/features/files/presentation/files_page.dart';

void main() {
  testWidgets('FilesPage shows file explorer cards and send action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fileTransferExplorerProvider.overrideWithValue(
            AsyncValue.data(<FileTransferExplorerItem>[
              FileTransferExplorerItem(
                contentHash: 'sha256:abc123',
                fileName: 'report.pdf',
                mimeType: 'application/pdf',
                kind: FileTransferKind.pdf,
                destinationNodeId: 'node-b',
                sourceNodeId: 'node-a',
                createdAt: DateTime(2026, 5, 30, 12, 0),
                lastUpdatedAt: DateTime(2026, 5, 30, 12, 5),
                totalBytes: 2048,
                expectedChunkCount: 7,
                chunkBundleIdsByIndex: <int, String>{0: 'chunk-0', 1: 'chunk-1', 2: 'chunk-2'},
                metadataBundleId: 'meta-1',
                localPath: '/tmp/report.pdf',
              ),
              FileTransferExplorerItem(
                contentHash: 'sha256:def456',
                fileName: 'photo.png',
                mimeType: 'image/png',
                kind: FileTransferKind.image,
                destinationNodeId: null,
                sourceNodeId: 'node-a',
                createdAt: DateTime(2026, 5, 30, 13, 0),
                lastUpdatedAt: DateTime(2026, 5, 30, 13, 1),
                totalBytes: 4096,
                expectedChunkCount: 2,
                chunkBundleIdsByIndex: <int, String>{0: 'chunk-a', 1: 'chunk-b'},
                metadataBundleId: 'meta-2',
                localPath: '/tmp/photo.png',
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: FilesPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('photo.png'), findsOneWidget);
    expect(find.textContaining('3/7 chunks'), findsOneWidget);
    expect(find.textContaining('Broadcast'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });
}
