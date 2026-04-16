import 'dart:typed_data';

class ContentStoreQuotaExceededException implements Exception {
  const ContentStoreQuotaExceededException({
    required this.maxBytes,
    required this.currentBytes,
    required this.requestedBytes,
  });

  final int maxBytes;
  final int currentBytes;
  final int requestedBytes;

  int get availableBytes => maxBytes - currentBytes;

  @override
  String toString() {
    return 'ContentStoreQuotaExceededException(maxBytes: $maxBytes, '
        'currentBytes: $currentBytes, requestedBytes: $requestedBytes)';
  }
}

abstract interface class ContentStore {
  Future<String?> put({required String contentHash, required Uint8List bytes});

  Future<Uint8List?> read({required String contentHash});
}
