import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/pending_web_search_request.dart';
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
          pendingWebSearchRequestsProvider.overrideWithValue(
            const AsyncValue.data(<PendingWebSearchRequest>[]),
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

  testWidgets('SearchPage shows pending local web search requests', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentWebIndexEntriesProvider.overrideWith(
            (ref) => Stream<List<WebIndexEntry>>.value(<WebIndexEntry>[]),
          ),
          pendingWebSearchRequestsProvider.overrideWithValue(
            AsyncValue.data(<PendingWebSearchRequest>[
              PendingWebSearchRequest(
                bundleId: 'web-search-1',
                query: 'mesh routing',
                createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
                expiresAt: DateTime.now().add(const Duration(hours: 3)),
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: SearchPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pending requests'), findsOneWidget);
    expect(find.text('mesh routing'), findsOneWidget);
    expect(find.textContaining('Waiting for gateway'), findsOneWidget);
  });
}
