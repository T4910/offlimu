class PendingWebSearchRequest {
  const PendingWebSearchRequest({
    required this.bundleId,
    required this.query,
    required this.createdAt,
    required this.expiresAt,
  });

  final String bundleId;
  final String query;
  final DateTime createdAt;
  final DateTime expiresAt;

  Duration timeToLive(DateTime now) {
    final remaining = expiresAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
