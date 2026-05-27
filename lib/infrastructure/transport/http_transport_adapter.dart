import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/services/discovery_adapter.dart';
import 'package:offlimu/domain/services/transport_adapter.dart';

class HttpTransportAdapter implements TransportAdapter {
  HttpTransportAdapter({
    required int listenPort,
    int sendMaxAttempts = 3,
    Duration connectTimeout = const Duration(seconds: 2),
    Duration requestTimeout = const Duration(seconds: 3),
    Duration backoffBaseDelay = const Duration(milliseconds: 250),
    Duration maxBackoffDelay = const Duration(seconds: 2),
  }) : _listenPort = listenPort,
       _sendMaxAttempts = sendMaxAttempts,
       _connectTimeout = connectTimeout,
       _requestTimeout = requestTimeout,
       _backoffBaseDelay = backoffBaseDelay,
       _maxBackoffDelay = maxBackoffDelay;

  final int _listenPort;
  final int _sendMaxAttempts;
  final Duration _connectTimeout;
  final Duration _requestTimeout;
  final Duration _backoffBaseDelay;
  final Duration _maxBackoffDelay;

  final StreamController<Bundle> _incomingController =
      StreamController<Bundle>.broadcast();
  final Map<String, DiscoveredPeer> _peersByNodeId = <String, DiscoveredPeer>{};

  HttpServer? _server;
  bool _started = false;
  HttpClient? _client;

  int get boundPort => _server?.port ?? _listenPort;

  @override
  Stream<Bundle> incomingBundles() => _incomingController.stream;

  @override
  void registerPeer(DiscoveredPeer peer) {
    _peersByNodeId[peer.nodeId] = peer;
  }

  @override
  Future<bool> isPeerAlive({required String peerNodeId}) async {
    final DiscoveredPeer? peer = _peersByNodeId[peerNodeId];
    if (peer == null) {
      return false;
    }

    final client = _client ??= HttpClient()..connectionTimeout = _connectTimeout;
    try {
      final request = await client
          .getUrl(Uri(scheme: 'http', host: peer.host, port: peer.port, path: '/v1/health'))
          .timeout(_connectTimeout);
      final response = await request.close().timeout(_requestTimeout);
      await response.drain<void>().timeout(_requestTimeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    _client ??= HttpClient()..connectionTimeout = _connectTimeout;

    final server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      _listenPort,
    );
    _server = server;
    unawaited(server.forEach(_handleRequest));
  }

  @override
  Future<void> stop() async {
    _started = false;
    await _server?.close(force: true);
    _server = null;
    _peersByNodeId.clear();
    _client?.close(force: true);
    _client = null;
  }

  @override
  Future<void> sendBundle({
    required String peerNodeId,
    required Bundle bundle,
  }) async {
    final DiscoveredPeer? peer = _peersByNodeId[peerNodeId];
    if (peer == null) {
      throw StateError('Unknown peer: $peerNodeId');
    }

    final Map<String, Object?> payload = _toWirePayload(bundle);
    final client = _client ??= HttpClient()..connectionTimeout = _connectTimeout;

    Object? lastError;
    final int maxAttempts = _sendMaxAttempts <= 0 ? 1 : _sendMaxAttempts;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final request = await client
            .postUrl(
              Uri(
                scheme: 'http',
                host: peer.host,
                port: peer.port,
                path: '/v1/bundles',
              ),
            )
            .timeout(_connectTimeout);
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode(payload)));
        final response = await request.close().timeout(_requestTimeout);
        await response.drain<void>().timeout(_requestTimeout);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }
        throw HttpException(
          'HTTP ${response.statusCode} from ${peer.host}:${peer.port}',
          uri: request.uri,
        );
      } catch (error) {
        lastError = error;
        if (attempt >= maxAttempts) {
          rethrow;
        }
        await Future<void>.delayed(_retryDelay(attempt));
      }
    }

    throw StateError(
      'Failed to send bundle after $maxAttempts attempts: ${lastError ?? 'unknown error'}',
    );
  }

  Duration _retryDelay(int attempt) {
    final int exponent = attempt - 1;
    if (exponent <= 0) {
      return _backoffBaseDelay;
    }
    final int scaledMs = _backoffBaseDelay.inMilliseconds * (1 << exponent);
    final int maxMs = _maxBackoffDelay.inMilliseconds;
    final int effectiveMs = scaledMs > maxMs ? maxMs : scaledMs;
    return Duration(milliseconds: effectiveMs);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      switch ((request.method.toUpperCase(), request.uri.path)) {
        case ('GET', '/v1/health'):
          await _writeJsonResponse(request.response, <String, Object?>{
            'ok': true,
          });
          break;
        case ('POST', '/v1/bundles'):
          final String body = await utf8.decoder.bind(request).join();
          final Bundle? bundle = _decodeBundle(body);
          if (bundle == null) {
            request.response.statusCode = HttpStatus.badRequest;
            await request.response.close();
            return;
          }
          _incomingController.add(bundle);
          request.response.statusCode = HttpStatus.accepted;
          await request.response.close();
          break;
        default:
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
      }
    } catch (_) {
      request.response.statusCode = HttpStatus.internalServerError;
      try {
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> _writeJsonResponse(
    HttpResponse response,
    Map<String, Object?> body,
  ) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }

  Map<String, Object?> _toWirePayload(Bundle bundle) {
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
    };
  }

  Bundle? _decodeBundle(String line) {
    try {
      final Object? parsed = jsonDecode(line);
      if (parsed is! Map<String, dynamic>) {
        return null;
      }

      final String? bundleId = parsed['bundleId'] as String?;
      final String? type = parsed['type'] as String?;
      final String? sourceNodeId = parsed['sourceNodeId'] as String?;
      final String? sourcePublicKey = parsed['sourcePublicKey'] as String?;
      final String? destinationNodeId = parsed['destinationNodeId'] as String?;
      final String? destinationScope = parsed['destinationScope'] as String?;
      final String? priority = parsed['priority'] as String?;
      final String? ackForBundleId = parsed['ackForBundleId'] as String?;
      final String? payload = parsed['payload'] as String?;
      final String? payloadRef = parsed['payloadRef'] as String?;
      final String? signature = parsed['signature'] as String?;
      final String appId = (parsed['appId'] as String?) ?? 'offlimu.chat';
      final int? createdAtMs = parsed['createdAtMs'] as int?;
      final int? expiresAtMs = parsed['expiresAtMs'] as int?;
      final int? ttlSeconds = parsed['ttlSeconds'] as int?;
      final int hopCount = (parsed['hopCount'] as int?) ?? 0;

      if (bundleId == null ||
          type == null ||
          sourceNodeId == null ||
          createdAtMs == null ||
          ttlSeconds == null) {
        return null;
      }

      return Bundle(
        bundleId: bundleId,
        type: type,
        sourceNodeId: sourceNodeId,
        sourcePublicKey: sourcePublicKey,
        destinationNodeId: destinationNodeId,
        destinationScope: Bundle.destinationScopeFromWire(destinationScope),
        priority: Bundle.priorityFromWire(priority),
        ackForBundleId: ackForBundleId,
        payload: payload,
        payloadReference: payloadRef,
        signature: signature,
        appId: appId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
        expiresAtOverride: expiresAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(expiresAtMs),
        ttlSeconds: ttlSeconds,
        hopCount: hopCount,
      );
    } catch (_) {
      return null;
    }
  }
}