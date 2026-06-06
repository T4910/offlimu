import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/file_transfer_explorer_item.dart';
import 'package:offlimu/features/debug/presentation/file_transfer_explorer_page.dart';

void main() {
  testWidgets('FileTransferExplorerPage shows summary and chunk map', (
    tester,
  ) async {
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
                chunkBundleIdsByIndex: <int, String>{
                  0: 'chunk-0',
                  1: 'chunk-1',
                  2: 'chunk-2',
                },
                metadataBundleId: 'meta-1',
                localPath: '/tmp/report.pdf',
                failedBundleCount: 0,
                lastError: null,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: FileTransferExplorerPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('File Transfer Explorer'), findsOneWidget);
    expect(find.text('Transfers: 1'), findsOneWidget);
    expect(find.text('Complete: 0'), findsOneWidget);
    expect(find.text('Incomplete: 1'), findsOneWidget);
    expect(find.text('#0'), findsOneWidget);
    expect(find.text('Metadata bundle: meta-1'), findsOneWidget);
  });
}
