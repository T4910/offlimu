import 'dart:io';
import 'dart:typed_data';

import 'package:offlimu/domain/services/content_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalFileContentStore implements ContentStore {
  LocalFileContentStore({this.maxStoreBytes});

  final int? maxStoreBytes;

  @override
  Future<String?> put({
    required String contentHash,
    required Uint8List bytes,
  }) async {
    final File file = await _resolveFile(contentHash);
    if (!await file.exists()) {
      final int? maxBytes = maxStoreBytes;
      if (maxBytes != null && maxBytes > 0) {
        final int currentBytes = await _calculateStoredBytes();
        if (currentBytes + bytes.length > maxBytes) {
          throw ContentStoreQuotaExceededException(
            maxBytes: maxBytes,
            currentBytes: currentBytes,
            requestedBytes: bytes.length,
          );
        }
      }
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.path;
  }

  @override
  Future<Uint8List?> read({required String contentHash}) async {
    final File file = await _resolveFile(contentHash);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  Future<File> _resolveFile(String contentHash) async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final String safeHash = _toSafeHash(contentHash);
    final String prefix = safeHash.length >= 2
        ? safeHash.substring(0, 2)
        : '00';
    final String filePath = p.join(
      docs.path,
      'offlimu_content',
      prefix,
      safeHash,
    );
    return File(filePath);
  }

  Future<int> _calculateStoredBytes() async {
    final Directory root = await _resolveRootDirectory();
    if (!await root.exists()) {
      return 0;
    }

    var total = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      total += await entity.length();
    }
    return total;
  }

  Future<Directory> _resolveRootDirectory() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'offlimu_content'));
  }

  String _toSafeHash(String raw) {
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}
