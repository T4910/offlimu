import 'dart:convert';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';

class SubmitWebSearchRequestUseCase {
  SubmitWebSearchRequestUseCase({
    required BundleRepository bundles,
    required BundleSignatureService bundleSignatureService,
    DateTime Function()? now,
    this.ttlSeconds = 86400,
  }) : _bundles = bundles,
       _bundleSignatureService = bundleSignatureService,
       _now = now ?? DateTime.now;

  final BundleRepository _bundles;
  final BundleSignatureService _bundleSignatureService;
  final DateTime Function() _now;
  final int ttlSeconds;

  Future<Bundle> submit({
    required String localNodeId,
    required String query,
    int maxResults = 3,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      throw ArgumentError('Search query must not be empty.');
    }

    final existing = await _findActiveRequest(
      localNodeId: localNodeId,
      query: normalizedQuery,
    );
    if (existing != null) {
      return existing;
    }

    final createdAt = _now();
    final bundle = Bundle(
      bundleId: 'web-search-${createdAt.microsecondsSinceEpoch}',
      type: Bundle.typeWebSearchRequest,
      sourceNodeId: localNodeId,
      destinationNodeId: null,
      destinationScope: BundleDestinationScope.broadcast,
      priority: BundlePriority.high,
      payload: jsonEncode(<String, Object?>{
        'query': normalizedQuery,
        'requestedByNodeId': localNodeId,
        'requestId': 'web-search-${createdAt.microsecondsSinceEpoch}',
        'maxResults': maxResults,
        'createdAtMs': createdAt.millisecondsSinceEpoch,
      }),
      appId: 'offlimu.web',
      createdAt: createdAt,
      ttlSeconds: ttlSeconds,
    );

    final signedBundle = await _bundleSignatureService.sign(
      bundle: bundle,
      nodeId: localNodeId,
    );
    await _bundles.save(signedBundle);
    return signedBundle;
  }

  Future<Bundle?> _findActiveRequest({
    required String localNodeId,
    required String query,
  }) async {
    final normalized = _normalizeQuery(query);
    final now = _now();
    final bundles = await _bundles.getAllBundles();
    for (final bundle in bundles) {
      if (bundle.type != Bundle.typeWebSearchRequest ||
          bundle.appId != 'offlimu.web' ||
          bundle.sourceNodeId != localNodeId ||
          bundle.acknowledged ||
          now.isAfter(bundle.expiresAt)) {
        continue;
      }
      final payload = bundle.payload;
      if (payload == null || payload.isEmpty) {
        continue;
      }
      try {
        final parsed = jsonDecode(payload);
        if (parsed is Map &&
            _normalizeQuery(parsed['query']?.toString() ?? '') == normalized) {
          return bundle;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  String _normalizeQuery(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }
}
