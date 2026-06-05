import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/web_index_entry.dart';
import 'package:offlimu/features/search/presentation/search_page.dart';

void main() {
  testWidgets('SearchPage shows cached web result tiles', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentWebIndexEntriesProvider.overrideWith(
            (ref) => Stream<List<WebIndexEntry>>.value(<WebIndexEntry>[
              WebIndexEntry(
                contentHash: 'sha256:cached',
                title: 'Cached mesh page',
                url: 'https://example.test/mesh',
                snippet: 'A cached offline web page.',
                query: 'mesh',
                sourceRequestId: 'request-1',
                createdAt: DateTime(2026, 6, 5),
                updatedAt: DateTime(2026, 6, 5),
                totalBytes: 128,
                expectedChunkCount: 1,
                receivedChunkCount: 1,
                availability: WebSnapshotAvailability.complete,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: SearchPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('OffLiMU Search'), findsOneWidget);
    expect(find.text('Cached mesh page'), findsOneWidget);
    expect(find.text('Cached'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });
}
