enum WebSnapshotAvailability { partial, complete }

class WebIndexEntry {
  const WebIndexEntry({
    required this.contentHash,
    required this.title,
    required this.url,
    required this.snippet,
    required this.query,
    required this.sourceRequestId,
    required this.createdAt,
    required this.updatedAt,
    required this.totalBytes,
    required this.expectedChunkCount,
    required this.receivedChunkCount,
    required this.availability,
  });

  final String contentHash;
  final String title;
  final String url;
  final String snippet;
  final String query;
  final String sourceRequestId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalBytes;
  final int expectedChunkCount;
  final int receivedChunkCount;
  final WebSnapshotAvailability availability;

  bool get isComplete => availability == WebSnapshotAvailability.complete;
}

class WebIndexEntryDraft {
  const WebIndexEntryDraft({
    required this.contentHash,
    required this.title,
    required this.url,
    required this.snippet,
    required this.query,
    required this.sourceRequestId,
    required this.totalBytes,
    required this.expectedChunkCount,
  });

  final String contentHash;
  final String title;
  final String url;
  final String snippet;
  final String query;
  final String sourceRequestId;
  final int totalBytes;
  final int expectedChunkCount;
}
