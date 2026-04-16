import 'package:drift/drift.dart';
import 'package:offlimu/domain/entities/sync_job_history_entry.dart';
import 'package:offlimu/domain/repositories/sync_job_repository.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';

class DriftSyncJobRepository implements SyncJobRepository {
  DriftSyncJobRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> saveRun(SyncJobHistoryEntry entry) {
    return _db.into(_db.syncJobs).insert(
          SyncJobsCompanion(
            startedAtMs: Value<int>(entry.startedAt.millisecondsSinceEpoch),
            completedAtMs: Value<int>(entry.completedAt.millisecondsSinceEpoch),
            uploadedCount: Value<int>(entry.uploadedCount),
            downloadedCount: Value<int>(entry.downloadedCount),
            success: Value<bool>(entry.success),
            mockMode: Value<bool>(entry.mockMode),
            gatewayEnabled: Value<bool>(entry.gatewayEnabled),
            internetReachable: Value<bool>(entry.internetReachable),
            errorMessage: Value<String?>(entry.errorMessage),
          ),
        );
  }

  @override
  Stream<List<SyncJobHistoryEntry>> watchRecentRuns({int limit = 20}) {
    final query = (_db.select(_db.syncJobs)
      ..orderBy(
        <OrderingTerm Function($SyncJobsTable)>[
          (tbl) => OrderingTerm.desc(tbl.completedAtMs),
        ],
      )
      ..limit(limit));

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => SyncJobHistoryEntry(
                  id: row.id,
                  startedAt: DateTime.fromMillisecondsSinceEpoch(row.startedAtMs),
                  completedAt:
                      DateTime.fromMillisecondsSinceEpoch(row.completedAtMs),
                  uploadedCount: row.uploadedCount,
                  downloadedCount: row.downloadedCount,
                  success: row.success,
                  mockMode: row.mockMode,
                  gatewayEnabled: row.gatewayEnabled,
                  internetReachable: row.internetReachable,
                  errorMessage: row.errorMessage,
                ),
              )
              .toList(growable: false),
        );
  }
}
