import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/sync_contract.dart';
import 'package:offlimu/domain/entities/web_search_result.dart';
import 'package:offlimu/domain/services/sync_api.dart';

class DioSyncApi implements SyncApi {
  DioSyncApi({required String baseUrl, this.mockMode = false})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  final Dio _dio;

  @override
  final bool mockMode;

  final List<Bundle> _mockRemoteInbox = <Bundle>[];

  @override
  Future<SyncUploadResult> uploadBundles(List<Bundle> bundles) async {
    if (bundles.isEmpty) {
      return const SyncUploadResult(
        acknowledgedBundleIds: <String>[],
        rejections: <SyncRejection>[],
      );
    }

    if (mockMode) {
      final List<String> acknowledged = <String>[];
      final List<SyncRejection> rejected = <SyncRejection>[];
      final List<WebSearchResult> webSearchResults = <WebSearchResult>[];

      for (final bundle in bundles) {
        final bool reject = (bundle.payload ?? '').contains('[reject]');
        if (reject) {
          final rejection = _buildRejectionFor(bundle);
          _mockRemoteInbox.add(rejection);
          rejected.add(
            SyncRejection(
              bundleId: bundle.bundleId,
              reason: rejection.payload ?? 'Rejected by server policy (mock)',
            ),
          );
        } else {
          final confirmation = _buildConfirmationFor(bundle);
          _mockRemoteInbox.add(confirmation);
          acknowledged.add(bundle.bundleId);
          if (bundle.type == Bundle.typeWebSearchRequest) {
            webSearchResults.addAll(_buildMockWebResultsFor(bundle));
          }
        }
      }

      return SyncUploadResult(
        acknowledgedBundleIds: acknowledged,
        rejections: rejected,
        webSearchResults: webSearchResults,
      );
    }

    final Response<dynamic> response;
    try {
      response = await _dio.post(
        '/sync/upload',
        data: <String, Object?>{
          'bundles': bundles.map(_bundleToJson).toList(growable: false),
        },
      );
    } on DioException catch (error) {
      throw SyncApiException(_describeDioError(error));
    }

    final data = _asMap(response.data);
    final acknowledged = _asStringList(data['acknowledgedBundleIds']);
    final rejectedRaw = data['rejections'];
    final rejected = rejectedRaw is List
        ? rejectedRaw
              .whereType<Map>()
              .map((raw) {
                final map = Map<String, dynamic>.from(raw);
                return SyncRejection(
                  bundleId: map['bundleId'] as String,
                  reason: (map['reason'] as String?) ?? 'Rejected by server',
                );
              })
              .toList(growable: false)
        : const <SyncRejection>[];
    final webResultsRaw = data['webSearchResults'];
    final webResults = webResultsRaw is List
        ? webResultsRaw
              .whereType<Map>()
              .map(
                (raw) =>
                    _webSearchResultFromJson(Map<String, dynamic>.from(raw)),
              )
              .toList(growable: false)
        : const <WebSearchResult>[];

    return SyncUploadResult(
      acknowledgedBundleIds: acknowledged,
      rejections: rejected,
      webSearchResults: webResults,
    );
  }

  @override
  Future<SyncFetchResult> fetchRemoteBundles({required DateTime since}) async {
    if (mockMode) {
      final List<Bundle> result = _mockRemoteInbox
          .where((bundle) => bundle.createdAt.isAfter(since))
          .toList(growable: false);
      _mockRemoteInbox.removeWhere((bundle) => result.contains(bundle));
      return SyncFetchResult(bundles: result);
    }

    final Response<dynamic> response;
    try {
      response = await _dio.get(
        '/sync/fetch',
        queryParameters: <String, Object?>{
          'sinceMs': since.millisecondsSinceEpoch,
        },
      );
    } on DioException catch (error) {
      throw SyncApiException(_describeDioError(error));
    }

    final Map<String, dynamic> data = _asMap(response.data);
    final Object? bundlesRaw = data['bundles'];
    if (bundlesRaw is! List) {
      return const SyncFetchResult(bundles: <Bundle>[]);
    }

    final bundles = bundlesRaw
        .whereType<Map>()
        .map((raw) => _bundleFromJson(Map<String, dynamic>.from(raw)))
        .toList(growable: false);

    return SyncFetchResult(bundles: bundles);
  }

  Map<String, Object?> _bundleToJson(Bundle bundle) {
    return <String, Object?>{
      'bundleId': bundle.bundleId,
      'type': bundle.type,
      'sourceNodeId': bundle.sourceNodeId,
      'sourcePublicKey': bundle.sourcePublicKey,
      'destinationNodeId': bundle.destinationNodeId,
      'destinationScope': bundle.destinationScope.name,
      'priority': bundle.priority.name,
      'ackForBundleId': bundle.ackForBundleId,
      'payload': bundle.payload,
      'payloadRef': bundle.payloadReference,
      'signature': bundle.signature,
      'appId': bundle.appId,
      'createdAtMs': bundle.createdAt.millisecondsSinceEpoch,
      'expiresAtMs': bundle.expiresAtOverride?.millisecondsSinceEpoch,
      'ttlSeconds': bundle.ttlSeconds,
      'hopCount': bundle.hopCount,
      'acknowledged': bundle.acknowledged,
      'sentAtMs': bundle.sentAt?.millisecondsSinceEpoch,
      'failedAttempts': bundle.failedAttempts,
      'lastError': bundle.lastError,
    };
  }

  Bundle _bundleFromJson(Map<String, dynamic> json) {
    return Bundle(
      bundleId: json['bundleId'] as String,
      type: json['type'] as String,
      sourceNodeId: json['sourceNodeId'] as String,
      sourcePublicKey: json['sourcePublicKey'] as String?,
      destinationNodeId: json['destinationNodeId'] as String?,
      destinationScope: Bundle.destinationScopeFromWire(
        json['destinationScope'] as String?,
      ),
      priority: Bundle.priorityFromWire(json['priority'] as String?),
      ackForBundleId: json['ackForBundleId'] as String?,
      payload: json['payload'] as String?,
      payloadReference: json['payloadRef'] as String?,
      signature: json['signature'] as String?,
      appId: (json['appId'] as String?) ?? 'offlimu.chat',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAtMs'] as int,
      ),
      expiresAtOverride: (json['expiresAtMs'] as int?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['expiresAtMs'] as int),
      ttlSeconds: json['ttlSeconds'] as int,
      hopCount: (json['hopCount'] as int?) ?? 0,
      acknowledged: (json['acknowledged'] as bool?) ?? false,
      sentAt: (json['sentAtMs'] as int?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['sentAtMs'] as int),
      failedAttempts: (json['failedAttempts'] as int?) ?? 0,
      lastError: json['lastError'] as String?,
    );
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
  }

  List<String> _asStringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw.whereType<String>().toList(growable: false);
  }

  Bundle _buildConfirmationFor(Bundle uploaded) {
    final now = DateTime.now();
    return Bundle(
      bundleId: 'server-ack-${uploaded.bundleId}-${now.microsecondsSinceEpoch}',
      type: Bundle.typeAck,
      sourceNodeId: 'server-gateway',
      destinationNodeId: uploaded.sourceNodeId,
      destinationScope: BundleDestinationScope.direct,
      priority: BundlePriority.normal,
      ackForBundleId: uploaded.bundleId,
      payload: null,
      appId: uploaded.appId,
      createdAt: now,
      ttlSeconds: 600,
      acknowledged: true,
    );
  }

  Bundle _buildRejectionFor(Bundle uploaded) {
    final now = DateTime.now();
    return Bundle(
      bundleId:
          'server-reject-${uploaded.bundleId}-${now.microsecondsSinceEpoch}',
      type: Bundle.typeSyncRejection,
      sourceNodeId: 'server-gateway',
      destinationNodeId: uploaded.sourceNodeId,
      destinationScope: BundleDestinationScope.direct,
      priority: BundlePriority.normal,
      ackForBundleId: uploaded.bundleId,
      payload: 'Rejected by server policy (mock)',
      appId: uploaded.appId,
      createdAt: now,
      ttlSeconds: 600,
      acknowledged: true,
    );
  }

  List<WebSearchResult> _buildMockWebResultsFor(Bundle request) {
    final payload = _asMap(_decodeJson(request.payload));
    final String query = (payload['query'] as String?)?.trim() ?? 'offline web';
    final int maxResults = ((payload['maxResults'] as num?)?.toInt() ?? 3)
        .clamp(1, 5);
    final normalized = query.isEmpty ? 'offline web' : query;

    return List<WebSearchResult>.generate(maxResults, (index) {
      final int ordinal = index + 1;
      final title = 'Offline result $ordinal for $normalized';
      final url =
          'https://mock.offlimu.local/search/${Uri.encodeComponent(normalized)}/$ordinal';
      final snippet =
          'A mock cached page about "$normalized" generated by the OffLiMU sync server.';
      return WebSearchResult(
        requestBundleId: request.bundleId,
        query: normalized,
        title: title,
        url: url,
        snippet: snippet,
        html: _mockHtml(
          title: title,
          url: url,
          query: normalized,
          snippet: snippet,
          ordinal: ordinal,
        ),
      );
    }, growable: false);
  }

  String _mockHtml({
    required String title,
    required String url,
    required String query,
    required String snippet,
    required int ordinal,
  }) {
    final escapedTitle = const HtmlEscape().convert(title);
    final escapedUrl = const HtmlEscape().convert(url);
    final escapedQuery = const HtmlEscape().convert(query);
    final escapedSnippet = const HtmlEscape().convert(snippet);
    return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$escapedTitle</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 0; color: #1f3524; background: #f6fbf4; }
    main { max-width: 760px; margin: 0 auto; padding: 32px 20px; }
    header { border-bottom: 1px solid #cfe3c8; margin-bottom: 24px; padding-bottom: 20px; }
    .source { color: #53715a; font-size: 14px; word-break: break-all; }
    .chip { display: inline-block; border: 1px solid #9cc69a; border-radius: 999px; padding: 6px 10px; margin: 0 8px 8px 0; color: #28562e; background: #eff8ec; }
    article { line-height: 1.65; font-size: 17px; }
  </style>
</head>
<body>
  <main>
    <header>
      <p class="source">$escapedUrl</p>
      <h1>$escapedTitle</h1>
      <p>$escapedSnippet</p>
    </header>
    <article>
      <p>This page is a deterministic mock snapshot generated for the query <strong>$escapedQuery</strong>.</p>
      <p>Result $ordinal contains an embedded HTML document so OffLiMU can test offline indexing, chunk transfer, and cached browsing without depending on live internet scraping yet.</p>
      <p><span class="chip">offline snapshot</span><span class="chip">mock sync server</span><span class="chip">DTN searchable cache</span></p>
    </article>
  </main>
</body>
</html>
''';
  }

  Object? _decodeJson(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(payload);
    } catch (_) {
      return null;
    }
  }

  WebSearchResult _webSearchResultFromJson(Map<String, dynamic> json) {
    return WebSearchResult(
      requestBundleId: json['requestBundleId'] as String,
      query: json['query'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      snippet: json['snippet'] as String,
      html: json['html'] as String,
    );
  }

  String _describeDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = _asMap(error.response?.data);
    final serverMessage = data['message'] as String?;
    final serverError = data['error'] as String?;
    if (serverMessage != null && serverMessage.isNotEmpty) {
      final prefix = statusCode == null
          ? 'Sync server error'
          : 'Sync server returned $statusCode';
      return serverError == null
          ? '$prefix: $serverMessage'
          : '$prefix ($serverError): $serverMessage';
    }
    if (statusCode != null) {
      return 'Sync server returned HTTP $statusCode.';
    }
    return 'Sync server request failed: ${error.message ?? error.type.name}.';
  }
}

class SyncApiException implements Exception {
  const SyncApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
