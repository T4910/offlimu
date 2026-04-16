import 'package:offlimu/domain/entities/sync_job_history_entry.dart';

abstract interface class SyncJobRepository {
  Future<void> saveRun(SyncJobHistoryEntry entry);
  Stream<List<SyncJobHistoryEntry>> watchRecentRuns({int limit = 20});
}
