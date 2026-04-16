class ContentMetadataRecord {
  const ContentMetadataRecord({
    required this.contentHash,
    this.mimeType,
    required this.totalBytes,
    this.chunkCount = 1,
    required this.createdAt,
    this.localPath,
  });

  final String contentHash;
  final String? mimeType;
  final int totalBytes;
  final int chunkCount;
  final DateTime createdAt;
  final String? localPath;
}
