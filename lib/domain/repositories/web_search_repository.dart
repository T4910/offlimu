import 'package:offlimu/domain/entities/web_index_entry.dart';

abstract interface class WebSearchRepository {
  Future<void> upsertEntry(WebIndexEntryDraft entry);
  Future<void> upsertEntries(Iterable<WebIndexEntryDraft> entries);
  Future<WebIndexEntry?> getByContentHash(String contentHash);
  Future<List<WebIndexEntry>> search(String query, {int limit = 20});
  Stream<List<WebIndexEntry>> watchSearch(String query, {int limit = 20});
  Stream<List<WebIndexEntry>> watchRecent({int limit = 50});
}
