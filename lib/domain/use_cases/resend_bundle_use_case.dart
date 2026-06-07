import 'dart:convert';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';

class ResendResult {
  const ResendResult({required this.requeuedCount});

  final int requeuedCount;

  bool get requeuedAny => requeuedCount > 0;
}

class ResendBundleUseCase {
  ResendBundleUseCase({required BundleRepository bundles}) : _bundles = bundles;

  final BundleRepository _bundles;

  Future<ResendResult> resendBundle(String bundleId) async {
    final bundle = await _bundles.getById(bundleId);
    if (bundle == null /*|| bundle.isExpired*/) {
      return const ResendResult(requeuedCount: 0);
    }
    await _bundles.resetForRetry(bundle.bundleId);
    return const ResendResult(requeuedCount: 1);
  }

  Future<ResendResult> resendChatMessage(String messageId) {
    return resendBundle(messageId);
  }

  Future<ResendResult> resendFileTransfer(String contentHash) async {
    final bundles = await _bundles.getAllBundles();
    final related = bundles
        .where(
          (bundle) =>
              (bundle.type == Bundle.typeFileShareMetadata ||
                  bundle.type == Bundle.typeFileShareChunk) &&
              _bundleReferencesContent(bundle, contentHash) &&
              !bundle.isExpired,
        )
        .toList(growable: false);

    for (final bundle in related) {
      await _bundles.resetForRetry(bundle.bundleId);
    }
    return ResendResult(requeuedCount: related.length);
  }

  bool _bundleReferencesContent(Bundle bundle, String contentHash) {
    if (bundle.payloadReference == contentHash) {
      return true;
    }
    final payload = bundle.payload;
    if (payload == null || payload.isEmpty) {
      return false;
    }
    try {
      final parsed = jsonDecode(payload);
      if (parsed is Map) {
        return parsed['contentHash'] == contentHash;
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}
