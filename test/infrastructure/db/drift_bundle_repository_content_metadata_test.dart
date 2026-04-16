import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';

void main() {
  group('DriftBundleRepository content metadata', () {
    test('saves and reads content metadata by hash', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final repository = DriftBundleRepository(db, localNodeId: 'node-test');
      final now = DateTime.now();
      const hash = 'sha256:abc123';

      await repository.saveContentMetadata(
        ContentMetadataRecord(
          contentHash: hash,
          mimeType: 'image/png',
          totalBytes: 4096,
          chunkCount: 4,
          createdAt: now,
          localPath: '/tmp/offlimu/file.png',
        ),
      );

      final saved = await repository.getContentMetadata(hash);

      expect(saved, isNotNull);
      expect(saved!.contentHash, hash);
      expect(saved.mimeType, 'image/png');
      expect(saved.totalBytes, 4096);
      expect(saved.chunkCount, 4);
      expect(saved.localPath, '/tmp/offlimu/file.png');
      expect(
        saved.createdAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });

    test('watchRecentContentMetadata returns newest entries first', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final repository = DriftBundleRepository(db, localNodeId: 'node-test');
      final oldTime = DateTime.fromMillisecondsSinceEpoch(1000);
      final newTime = DateTime.fromMillisecondsSinceEpoch(2000);

      await repository.saveContentMetadata(
        ContentMetadataRecord(
          contentHash: 'sha256:old',
          mimeType: 'text/plain',
          totalBytes: 10,
          createdAt: oldTime,
        ),
      );
      await repository.saveContentMetadata(
        ContentMetadataRecord(
          contentHash: 'sha256:new',
          mimeType: 'text/plain',
          totalBytes: 20,
          createdAt: newTime,
        ),
      );

      final entries = await repository
          .watchRecentContentMetadata(limit: 2)
          .first;

      expect(entries, hasLength(2));
      expect(entries.first.contentHash, 'sha256:new');
      expect(entries.last.contentHash, 'sha256:old');
    });
  });
}
