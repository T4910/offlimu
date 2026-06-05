import 'package:drift/drift.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/web_index_entry.dart';
import 'package:offlimu/domain/repositories/web_search_repository.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';

class DriftWebSearchRepository implements WebSearchRepository {
  DriftWebSearchRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> upsertEntry(WebIndexEntryDraft entry) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    return _db
        .into(_db.webIndexRecords)
        .insertOnConflictUpdate(
          WebIndexRecordsCompanion(
            contentHash: Value<String>(entry.contentHash),
            title: Value<String>(entry.title),
            url: Value<String>(entry.url),
            snippet: Value<String>(entry.snippet),
            query: Value<String>(entry.query),
            sourceRequestId: Value<String>(entry.sourceRequestId),
            totalBytes: Value<int>(entry.totalBytes),
            expectedChunkCount: Value<int>(entry.expectedChunkCount),
            createdAtMs: Value<int>(nowMs),
            updatedAtMs: Value<int>(nowMs),
          ),
        );
  }

  @override
  Future<void> upsertEntries(Iterable<WebIndexEntryDraft> entries) {
    return _db.transaction(() async {
      for (final entry in entries) {
        await upsertEntry(entry);
      }
    });
  }

  @override
  Future<WebIndexEntry?> getByContentHash(String contentHash) async {
    final row = await (_db.select(
      _db.webIndexRecords,
    )..where((tbl) => tbl.contentHash.equals(contentHash))).getSingleOrNull();
    return row == null ? null : _hydrate(row);
  }

  @override
  Future<List<WebIndexEntry>> search(String query, {int limit = 20}) async {
    final statement = _searchQuery(query, limit);
    final rows = await statement.get();
    return _hydrateAll(rows);
  }

  @override
  Stream<List<WebIndexEntry>> watchSearch(String query, {int limit = 20}) {
    final statement = _searchQuery(query, limit);
    return statement.watch().asyncMap(_hydrateAll);
  }

  @override
  Stream<List<WebIndexEntry>> watchRecent({int limit = 50}) {
    final statement = _db.select(_db.webIndexRecords)
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.updatedAtMs),
        (tbl) => OrderingTerm.asc(tbl.title),
      ])
      ..limit(limit);
    return statement.watch().asyncMap(_hydrateAll);
  }

  SimpleSelectStatement<$WebIndexRecordsTable, WebIndexRecord> _searchQuery(
    String query,
    int limit,
  ) {
    final String normalized = query.trim().toLowerCase();
    final statement = _db.select(_db.webIndexRecords)
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.updatedAtMs),
        (tbl) => OrderingTerm.asc(tbl.title),
      ])
      ..limit(limit);

    if (normalized.isEmpty) {
      return statement;
    }

    final String pattern = '%${_escapeLike(normalized)}%';
    statement.where(
      (tbl) =>
          tbl.title.lower().like(pattern) |
          tbl.url.lower().like(pattern) |
          tbl.snippet.lower().like(pattern) |
          tbl.query.lower().like(pattern),
    );
    return statement;
  }

  Future<List<WebIndexEntry>> _hydrateAll(List<WebIndexRecord> rows) async {
    final entries = <WebIndexEntry>[];
    for (final row in rows) {
      entries.add(await _hydrate(row));
    }
    return entries;
  }

  Future<WebIndexEntry> _hydrate(WebIndexRecord row) async {
    final metadata =
        await (_db.select(_db.contentMetadata)
              ..where((tbl) => tbl.contentHash.equals(row.contentHash)))
            .getSingleOrNull();
    final chunkCountExpression = _db.bundleRecords.bundleId.count();
    final chunkQuery = _db.selectOnly(_db.bundleRecords)
      ..addColumns([chunkCountExpression])
      ..where(
        _db.bundleRecords.payloadRef.equals(row.contentHash) &
            _db.bundleRecords.type.equals(Bundle.typeFileShareChunk),
      );
    final chunkCount = await chunkQuery
        .map((result) => result.read(chunkCountExpression) ?? 0)
        .getSingle();
    final bool complete = metadata?.localPath != null;
    final int expectedChunks = metadata?.chunkCount ?? row.expectedChunkCount;
    return WebIndexEntry(
      contentHash: row.contentHash,
      title: row.title,
      url: row.url,
      snippet: row.snippet,
      query: row.query,
      sourceRequestId: row.sourceRequestId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAtMs),
      totalBytes: metadata?.totalBytes ?? row.totalBytes,
      expectedChunkCount: expectedChunks,
      receivedChunkCount: complete ? expectedChunks : chunkCount,
      availability: complete
          ? WebSnapshotAvailability.complete
          : WebSnapshotAvailability.partial,
    );
  }

  String _escapeLike(String value) {
    return value.replaceAll('%', r'\%').replaceAll('_', r'\_');
  }
}
