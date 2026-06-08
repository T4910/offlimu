import 'dart:convert';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/services/content_store.dart';

class RemoveFileTransferResult {
  const RemoveFileTransferResult({
    required this.deletedBundleCount,
    required this.deletedContentHash,
  });

  final int deletedBundleCount;
  final String deletedContentHash;
}

class RemoveFileTransferUseCase {
  RemoveFileTransferUseCase({
    required BundleRepository bundles,
    required ContentStore contentStore,
  }) : _bundles = bundles,
       _contentStore = contentStore;

  final BundleRepository _bundles;
  final ContentStore _contentStore;

  Future<RemoveFileTransferResult> remove(String contentHash) async {
    final normalizedHash = contentHash.trim();
    if (normalizedHash.isEmpty) {
      throw ArgumentError('Content hash must not be empty.');
    }

    final allBundles = await _bundles.getAllBundles();
    final matchingBundleIds = allBundles
        .where((bundle) => _isFileBundleForHash(bundle, normalizedHash))
        .map((bundle) => bundle.bundleId)
        .toSet();

    for (final bundleId in matchingBundleIds) {
      await _bundles.deleteBundle(bundleId);
    }

    await _bundles.deleteContentMetadata(normalizedHash);
    await _contentStore.delete(contentHash: normalizedHash);

    return RemoveFileTransferResult(
      deletedBundleCount: matchingBundleIds.length,
      deletedContentHash: normalizedHash,
    );
  }

  bool _isFileBundleForHash(Bundle bundle, String contentHash) {
    if (bundle.type != Bundle.typeFileShareMetadata &&
        bundle.type != Bundle.typeFileShareChunk) {
      return false;
    }
    if (bundle.payloadReference == contentHash) {
      return true;
    }
    final payload = bundle.payload;
    if (payload == null || payload.isEmpty) {
      return false;
    }
    try {
      final parsed = jsonDecode(payload);
      return parsed is Map && parsed['contentHash'] == contentHash;
    } catch (_) {
      return false;
    }
  }
}
