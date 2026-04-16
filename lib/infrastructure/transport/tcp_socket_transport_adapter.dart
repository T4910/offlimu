import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/services/discovery_adapter.dart';
import 'package:offlimu/domain/services/transport_adapter.dart';

class TcpSocketTransportAdapter implements TransportAdapter {
  TcpSocketTransportAdapter({
    required int listenPort,
    int sendMaxAttempts = 3,
    Duration connectTimeout = const Duration(seconds: 2),
    Duration backoffBaseDelay = const Duration(milliseconds: 250),
    Duration maxBackoffDelay = const Duration(seconds: 2),
  }) : _listenPort = listenPort,
       _sendMaxAttempts = sendMaxAttempts,
       _connectTimeout = connectTimeout,
       _backoffBaseDelay = backoffBaseDelay,
       _maxBackoffDelay = maxBackoffDelay;

  final int _listenPort;
  final int _sendMaxAttempts;
  final Duration _connectTimeout;
  final Duration _backoffBaseDelay;
  final Duration _maxBackoffDelay;

  final StreamController<Bundle> _incomingController =
      StreamController<Bundle>.broadcast();
  final Map<String, DiscoveredPeer> _peersByNodeId = <String, DiscoveredPeer>{};
  static const int _maxFrameLengthBytes = 8 * 1024 * 1024;

  ServerSocket? _serverSocket;
  StreamSubscription<Socket>? _acceptSubscription;
  final List<StreamSubscription<List<int>>> _clientSubscriptions =
      <StreamSubscription<List<int>>>[];
  bool _started = false;

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

    Socket? socket;
    try {
      socket = await Socket.connect(
        peer.host,
        peer.port,
        timeout: _connectTimeout,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      await socket?.close();
    }
  }

  @override
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    final ServerSocket server = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      _listenPort,
    );
    _serverSocket = server;
    _acceptSubscription = server.listen(_handleIncomingSocket);
  }

  @override
  Future<void> stop() async {
    _started = false;

    for (final sub in _clientSubscriptions) {
      await sub.cancel();
    }
    _clientSubscriptions.clear();

    await _acceptSubscription?.cancel();
    _acceptSubscription = null;

    await _serverSocket?.close();
    _serverSocket = null;

    _peersByNodeId.clear();
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

    final Map<String, Object?> payload = <String, Object?>{
      'bundleId': bundle.bundleId,
      'type': bundle.type,
      'sourceNodeId': bundle.sourceNodeId,
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
    final List<int> encodedBytes = utf8.encode(jsonEncode(payload));
    final ByteData header = ByteData(4)
      ..setUint32(0, encodedBytes.length, Endian.big);

    Object? lastError;
    final int maxAttempts = _sendMaxAttempts <= 0 ? 1 : _sendMaxAttempts;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      Socket? socket;
      try {
        socket = await Socket.connect(
          peer.host,
          peer.port,
          timeout: _connectTimeout,
        );
        socket.add(header.buffer.asUint8List());
        socket.add(encodedBytes);
        await socket.flush();
        return;
      } catch (error) {
        lastError = error;
        if (attempt >= maxAttempts) {
          rethrow;
        }
        await Future<void>.delayed(_retryDelay(attempt));
      } finally {
        await socket?.close();
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

  void _handleIncomingSocket(Socket socket) {
    final _LengthPrefixedFrameParser parser = _LengthPrefixedFrameParser(
      maxFrameLengthBytes: _maxFrameLengthBytes,
    );

    final StreamSubscription<List<int>> sub = socket.listen(
      (chunk) {
        try {
          for (final String frame in parser.addChunk(chunk)) {
            final Bundle? bundle = _decodeBundle(frame);
            if (bundle != null) {
              _incomingController.add(bundle);
            }
          }
        } catch (_) {
          socket.destroy();
        }
      },
      onDone: () => socket.destroy(),
      onError: (error, stackTrace) => socket.destroy(),
      cancelOnError: true,
    );
    _clientSubscriptions.add(sub);
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

class _LengthPrefixedFrameParser {
  _LengthPrefixedFrameParser({required this.maxFrameLengthBytes});

  final int maxFrameLengthBytes;
  final List<int> _buffer = <int>[];

  List<String> addChunk(List<int> chunk) {
    _buffer.addAll(chunk);
    final List<String> frames = <String>[];

    while (true) {
      if (_buffer.length < 4) {
        break;
      }

      final int frameLength =
          (_buffer[0] << 24) |
          (_buffer[1] << 16) |
          (_buffer[2] << 8) |
          _buffer[3];

      if (frameLength <= 0 || frameLength > maxFrameLengthBytes) {
        throw const FormatException('Invalid frame length');
      }

      final int totalFrameBytes = 4 + frameLength;
      if (_buffer.length < totalFrameBytes) {
        break;
      }

      final List<int> payloadBytes = _buffer.sublist(4, totalFrameBytes);
      frames.add(utf8.decode(payloadBytes));
      _buffer.removeRange(0, totalFrameBytes);
    }

    return frames;
  }
}
