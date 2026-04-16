import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  group('AppDatabase migrations', () {
    test('migrates v9 schema to v11 and preserves rows', () async {
      final tempDir = await Directory.systemTemp.createTemp('offlimu-db-');
      final dbFile = File(p.join(tempDir.path, 'offlimu.sqlite'));

      final raw = sqlite.sqlite3.open(dbFile.path);
      try {
        raw.execute('PRAGMA user_version = 9;');

        raw.execute('''
CREATE TABLE bundle_records (
  bundle_id TEXT NOT NULL PRIMARY KEY,
  type TEXT NOT NULL,
  source_node_id TEXT NOT NULL,
  destination_node_id TEXT,
  ack_for_bundle_id TEXT,
  payload TEXT,
  created_at_ms INTEGER NOT NULL,
  ttl_seconds INTEGER NOT NULL,
  hop_count INTEGER NOT NULL DEFAULT 0,
  acknowledged INTEGER NOT NULL DEFAULT 0,
  sent_at_ms INTEGER,
  failed_attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT
);
''');

        raw.execute('''
CREATE TABLE peer_contacts (
  node_id TEXT NOT NULL PRIMARY KEY,
  host TEXT NOT NULL,
  port INTEGER NOT NULL,
  last_seen_ms INTEGER NOT NULL,
  seen_count INTEGER NOT NULL DEFAULT 1
);
''');

        raw.execute('''
CREATE TABLE sync_jobs (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  started_at_ms INTEGER NOT NULL,
  completed_at_ms INTEGER NOT NULL,
  uploaded_count INTEGER NOT NULL DEFAULT 0,
  downloaded_count INTEGER NOT NULL DEFAULT 0,
  success INTEGER NOT NULL,
  mock_mode INTEGER NOT NULL,
  gateway_enabled INTEGER NOT NULL,
  internet_reachable INTEGER NOT NULL,
  error_message TEXT
);
''');

        raw.execute('''
CREATE TABLE message_projections (
  bundle_id TEXT NOT NULL PRIMARY KEY,
  source_node_id TEXT NOT NULL,
  destination_node_id TEXT,
  body TEXT NOT NULL,
  created_at_ms INTEGER NOT NULL,
  is_outgoing INTEGER NOT NULL,
  delivery_status TEXT NOT NULL,
  failed_attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT
);
''');

        raw.execute('''
CREATE TABLE ack_events (
  ack_bundle_id TEXT NOT NULL PRIMARY KEY,
  ack_for_bundle_id TEXT,
  source_node_id TEXT NOT NULL,
  first_received_at_ms INTEGER NOT NULL,
  last_received_at_ms INTEGER NOT NULL,
  duplicate_count INTEGER NOT NULL DEFAULT 0
);
''');

        raw.execute('''
INSERT INTO bundle_records (
  bundle_id,
  type,
  source_node_id,
  destination_node_id,
  payload,
  created_at_ms,
  ttl_seconds,
  hop_count,
  acknowledged,
  failed_attempts
) VALUES (
  'legacy-1',
  'chat_message',
  'node-a',
  'node-b',
  'hello',
  1700000000000,
  3600,
  0,
  0,
  0
);
''');
      } finally {
        raw.dispose();
      }

      final db = AppDatabase.forTesting(NativeDatabase(dbFile));
      addTearDown(() async {
        await db.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      await db.customSelect('SELECT 1').get();

      final columnRows = await db
          .customSelect('PRAGMA table_info(bundle_records)')
          .get();
      final columns = columnRows
          .map((row) => row.data['name'] as String)
          .toSet();

      expect(columns, contains('destination_scope'));
      expect(columns, contains('priority'));
      expect(columns, contains('payload_ref'));
      expect(columns, contains('signature'));
      expect(columns, contains('app_id'));
      expect(columns, contains('expires_at_ms'));

      final contentMetadataTableRows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'content_metadata'",
          )
          .get();
      expect(contentMetadataTableRows, isNotEmpty);

      final legacy = await db
          .customSelect(
            '''
SELECT
  bundle_id,
  destination_scope,
  priority,
  payload_ref,
  signature,
  app_id,
  expires_at_ms
FROM bundle_records
WHERE bundle_id = ?
''',
            variables: <Variable<Object>>[Variable<Object>('legacy-1')],
          )
          .getSingle();

      expect(legacy.data['bundle_id'], 'legacy-1');
      expect(legacy.data['destination_scope'], 'direct');
      expect(legacy.data['priority'], 'normal');
      expect(legacy.data['payload_ref'], equals(null));
      expect(legacy.data['signature'], equals(null));
      expect(legacy.data['app_id'], 'offlimu.chat');
      expect(legacy.data['expires_at_ms'], equals(null));
    });

    test(
      'fresh v11 schema includes DTN metadata and content metadata table',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        final version = await db
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 11);

        final columnRows = await db
            .customSelect('PRAGMA table_info(bundle_records)')
            .get();
        final columns = columnRows
            .map((row) => row.data['name'] as String)
            .toSet();

        expect(
          columns,
          containsAll(<String>{
            'destination_scope',
            'priority',
            'payload_ref',
            'signature',
            'app_id',
            'expires_at_ms',
          }),
        );

        final contentMetadataColumns = await db
            .customSelect('PRAGMA table_info(content_metadata)')
            .get();
        final contentMetadataColumnNames = contentMetadataColumns
            .map((row) => row.data['name'] as String)
            .toSet();

        expect(
          contentMetadataColumnNames,
          containsAll(<String>{
            'content_hash',
            'mime_type',
            'total_bytes',
            'chunk_count',
            'created_at_ms',
            'local_path',
          }),
        );
      },
    );
  });
}
