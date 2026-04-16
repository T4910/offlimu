class AckAuditEvent {
  const AckAuditEvent({
    required this.ackBundleId,
    required this.ackForBundleId,
    required this.sourceNodeId,
    required this.firstReceivedAt,
    required this.lastReceivedAt,
    required this.duplicateCount,
  });

  final String ackBundleId;
  final String? ackForBundleId;
  final String sourceNodeId;
  final DateTime firstReceivedAt;
  final DateTime lastReceivedAt;
  final int duplicateCount;

  int get totalReceipts => duplicateCount + 1;
}
