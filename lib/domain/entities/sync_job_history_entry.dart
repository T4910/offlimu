class SyncJobHistoryEntry {
  const SyncJobHistoryEntry({
    this.id,
    required this.startedAt,
    required this.completedAt,
    required this.uploadedCount,
    required this.downloadedCount,
    required this.success,
    required this.mockMode,
    required this.gatewayEnabled,
    required this.internetReachable,
    this.errorMessage,
  });

  final int? id;
  final DateTime startedAt;
  final DateTime completedAt;
  final int uploadedCount;
  final int downloadedCount;
  final bool success;
  final bool mockMode;
  final bool gatewayEnabled;
  final bool internetReachable;
  final String? errorMessage;
}
