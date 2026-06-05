import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/infrastructure/sync/dio_sync_api.dart';

void main() {
  test(
    'mock sync api returns deterministic web results for search requests',
    () async {
      final api = DioSyncApi(baseUrl: 'http://localhost:8080', mockMode: true);
      final request = Bundle(
        bundleId: 'request-1',
        type: Bundle.typeWebSearchRequest,
        sourceNodeId: 'node-a',
        destinationNodeId: null,
        destinationScope: BundleDestinationScope.broadcast,
        priority: BundlePriority.high,
        payload: jsonEncode(<String, Object?>{
          'query': 'offline mesh',
          'maxResults': 2,
        }),
        appId: 'offlimu.web',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        ttlSeconds: 86400,
      );

      final result = await api.uploadBundles(<Bundle>[request]);

      expect(result.acknowledgedBundleIds, contains('request-1'));
      expect(result.webSearchResults, hasLength(2));
      expect(result.webSearchResults.first.requestBundleId, 'request-1');
      expect(result.webSearchResults.first.query, 'offline mesh');
      expect(result.webSearchResults.first.html, contains('<!doctype html>'));
    },
  );
}
