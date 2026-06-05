import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/entities/web_index_entry.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';
import 'package:offlimu/infrastructure/db/drift_web_search_repository.dart';

void main() {
  test(
    'search filters web entries and derives complete availability',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final webRepository = DriftWebSearchRepository(db);
      final bundleRepository = DriftBundleRepository(db, localNodeId: 'node-a');
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);

      await webRepository.upsertEntry(
        const WebIndexEntryDraft(
          contentHash: 'sha256:offline',
          title: 'Offline networking guide',
          url: 'https://example.test/offline',
          snippet: 'DTN pages that can be browsed without internet.',
          query: 'offline networking',
          sourceRequestId: 'request-1',
          totalBytes: 512,
          expectedChunkCount: 2,
        ),
      );
      await bundleRepository.saveContentMetadata(
        ContentMetadataRecord(
          contentHash: 'sha256:offline',
          mimeType: 'text/html',
          totalBytes: 512,
          chunkCount: 2,
          createdAt: now,
          localPath: '/tmp/offline.html',
        ),
      );

      final results = await webRepository.search('networking');

      expect(results, hasLength(1));
      expect(results.single.title, 'Offline networking guide');
      expect(results.single.availability, WebSnapshotAvailability.complete);
      expect(results.single.receivedChunkCount, 2);
    },
  );

  test('entry remains partial until content metadata has local path', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final webRepository = DriftWebSearchRepository(db);
    final bundleRepository = DriftBundleRepository(db, localNodeId: 'node-a');
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    await webRepository.upsertEntry(
      const WebIndexEntryDraft(
        contentHash: 'sha256:partial',
        title: 'Partial page',
        url: 'https://example.test/partial',
        snippet: 'Only one chunk has arrived.',
        query: 'partial',
        sourceRequestId: 'request-2',
        totalBytes: 1024,
        expectedChunkCount: 3,
      ),
    );
    await bundleRepository.save(
      Bundle(
        bundleId: 'chunk-1',
        type: Bundle.typeFileShareChunk,
        sourceNodeId: 'node-b',
        destinationNodeId: null,
        destinationScope: BundleDestinationScope.broadcast,
        payloadReference: 'sha256:partial',
        appId: 'offlimu.web',
        createdAt: now,
        ttlSeconds: 3600,
      ),
    );

    final entry = await webRepository.getByContentHash('sha256:partial');

    expect(entry, isNotNull);
    expect(entry!.availability, WebSnapshotAvailability.partial);
    expect(entry.receivedChunkCount, 1);
    expect(entry.expectedChunkCount, 3);
  });
}
