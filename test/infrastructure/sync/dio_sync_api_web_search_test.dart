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

      expect(result.rejections, isEmpty);
      expect(result.webSearchResults, hasLength(2));
      expect(result.webSearchResults.first.requestBundleId, 'request-1');
      expect(result.webSearchResults.first.query, 'offline mesh');
      expect(result.webSearchResults.first.html, contains('<!doctype html>'));
    },
  );

  test('mock sync api does not fabricate ACKs for generic bundles', () async {
    final api = DioSyncApi(baseUrl: 'http://localhost:8080', mockMode: true);
    final chat = Bundle(
      bundleId: 'chat-1',
      type: Bundle.typeChatMessage,
      sourceNodeId: 'node-a',
      destinationNodeId: 'node-b',
      payload: 'hello',
      appId: 'offlimu.chat',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      ttlSeconds: 3600,
    );

    final upload = await api.uploadBundles(<Bundle>[chat]);
    final fetch = await api.fetchRemoteBundles(
      since: DateTime.fromMillisecondsSinceEpoch(0),
    );

    expect(upload.rejections, isEmpty);
    expect(fetch.bundles, isEmpty);
  });

  test(
    'mock sync api returns wallet confirmations for wallet spends',
    () async {
      final api = DioSyncApi(baseUrl: 'http://localhost:8080', mockMode: true);
      final spend = Bundle(
        bundleId: 'spend-1',
        type: Bundle.typeWalletSpend,
        sourceNodeId: 'node-a',
        destinationNodeId: 'node-b',
        payload: jsonEncode(<String, Object?>{
          'kind': 'spend',
          'recipientNodeId': 'node-b',
          'amountMinorUnits': 1200,
          'memo': 'mock spend',
          'createdAtMs': 1700000000000,
        }),
        appId: 'offlimu.wallet',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        ttlSeconds: 3600,
      );

      await api.uploadBundles(<Bundle>[spend]);
      final fetch = await api.fetchRemoteBundles(
        since: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(fetch.bundles, hasLength(1));
      expect(fetch.bundles.single.type, Bundle.typeWalletConfirmation);
      expect(fetch.bundles.single.ackForBundleId, 'spend-1');
    },
  );
}
