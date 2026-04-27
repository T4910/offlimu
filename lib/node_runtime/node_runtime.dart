import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/entities/peer_contact.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/peer_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/services/discovery_adapter.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/services/logger_service.dart';
import 'package:offlimu/domain/services/transport_adapter.dart';
import 'package:offlimu/node_runtime/node_runtime_state.dart';

class NodeRuntime {
  NodeRuntime({
    required String localNodeId,
    required DiscoveryAdapter discovery,
    required TransportAdapter transport,
    required BundleRepository bundles,
    required PeerRepository peers,
    required ContentStore contentStore,
    required BundleSignatureService bundleSignatureService,
    this.maxHopCount = 5,
    this.maxSendAttempts = 5,
    this.retryBaseDelay = const Duration(seconds: 2),
    this.maxRetryDelay = const Duration(minutes: 2),
    this.peerStaleAfter = const Duration(seconds: 45),
    this.duplicatePeerSuppressionWindow = const Duration(seconds: 8),
    this.peerLivenessFailureThreshold = 2,
    LoggerService? logger,
  }) : _localNodeId = localNodeId,
       _discovery = discovery,
       _transport = transport,
       _bundles = bundles,
       _peerRepository = peers,
       _contentStore = contentStore,
       _bundleSignatureService = bundleSignatureService,
       _logger = logger {
    _healthController.add(_health);
    _peerCountController.add(_peerCount);
    _telemetryController.add(_telemetry);
  }

  final String _localNodeId;

  final DiscoveryAdapter _discovery;
  final TransportAdapter _transport;
  final BundleRepository _bundles;
  final PeerRepository _peerRepository;
  final ContentStore _contentStore;
  final BundleSignatureService _bundleSignatureService;
  final LoggerService? _logger;
  final int maxHopCount;
  final int maxSendAttempts;
  final Duration retryBaseDelay;
  final Duration maxRetryDelay;
  final Duration peerStaleAfter;
  final Duration duplicatePeerSuppressionWindow;
  final int peerLivenessFailureThreshold;
  final Map<String, DiscoveredPeer> _peers = <String, DiscoveredPeer>{};
  final Map<String, DateTime> _peerSeenAt = <String, DateTime>{};
  final Map<String, DateTime> _peerLastUpsertAt = <String, DateTime>{};
  final Map<String, int> _peerLivenessFailures = <String, int>{};
  final Map<String, _PeerRoutingStats> _peerRoutingStats =
      <String, _PeerRoutingStats>{};
  final Map<String, _FileTransferAssembly> _fileTransferAssemblies =
      <String, _FileTransferAssembly>{};

  final StreamController<RuntimeHealth> _healthController =
      StreamController<RuntimeHealth>.broadcast();
  final StreamController<int> _peerCountController =
      StreamController<int>.broadcast();
  final StreamController<RuntimeTelemetry> _telemetryController =
      StreamController<RuntimeTelemetry>.broadcast();

  StreamSubscription<dynamic>? _discoverySubscription;
  StreamSubscription<dynamic>? _incomingBundleSubscription;
  Timer? _forwardTimer;
  Timer? _livenessTimer;
  Future<void> _orchestrationTail = Future<void>.value();

  RuntimeHealth _health = RuntimeHealth.idle;
  RuntimeTelemetry _telemetry = const RuntimeTelemetry();
  int _peerCount = 0;
  bool _isForwarding = false;
  bool _started = false;
  bool _disposed = false;

  RuntimeHealth get health => _health;
  RuntimeTelemetry get telemetry => _telemetry;
  int get peerCount => _peerCount;
  bool get isRunning => _started;

  Stream<RuntimeHealth> get healthStream => _healthController.stream;
  Stream<RuntimeTelemetry> get telemetryStream => _telemetryController.stream;
  Stream<int> get peerCountStream => _peerCountController.stream;

  Future<void> start() async {
    await _enqueueOrchestration(_startLocked);
  }

  Future<void> stop() async {
    await _enqueueOrchestration(_stopLocked);
  }

  Future<void> dispose() async {
    await _enqueueOrchestration(() async {
      if (_disposed) {
        return;
      }

      _disposed = true;
      await _stopLocked();
      await _healthController.close();
      await _peerCountController.close();
      await _telemetryController.close();
    });
  }

  Future<void> flushPendingNow() {
    return _enqueueOrchestration(_flushPendingOutboundBundlesLocked);
  }

  Future<void> _enqueueOrchestration(Future<void> Function() action) {
    final Completer<void> completer = Completer<void>();
    _orchestrationTail = _orchestrationTail
        .then((_) async {
          if (_disposed) {
            if (!completer.isCompleted) {
              completer.complete();
            }
            return;
          }

          try {
            await action();
            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (error, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          }
        })
        .catchError((_) {});
    return completer.future;
  }

  Future<void> _startLocked() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;

    _setHealth(RuntimeHealth.starting);
    _logger?.info(
      'runtime_starting',
      scope: 'runtime',
      fields: {'nodeId': _localNodeId},
    );

    await _transport.start();
    await _discovery.start();

    _setHealth(RuntimeHealth.discovering);

    _discoverySubscription = _discovery.discover().listen(
      _handleDiscoveredPeer,
    );

    _incomingBundleSubscription = _transport.incomingBundles().listen((bundle) {
      unawaited(_handleIncomingBundle(bundle));
    });

    _forwardTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_flushPendingOutboundBundlesLocked());
    });

    _livenessTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_runPeerLivenessChecks());
    });

    _logger?.info(
      'runtime_started',
      scope: 'runtime',
      fields: {'nodeId': _localNodeId, 'health': _health.name},
    );
  }

  Future<void> _stopLocked() async {
    if (!_started) {
      return;
    }
    _setHealth(RuntimeHealth.stopping);
    _started = false;

    _forwardTimer?.cancel();
    _forwardTimer = null;

    _livenessTimer?.cancel();
    _livenessTimer = null;

    await _incomingBundleSubscription?.cancel();
    _incomingBundleSubscription = null;

    await _discoverySubscription?.cancel();
    _discoverySubscription = null;

    _peers.clear();
    _peerSeenAt.clear();
    _peerLastUpsertAt.clear();
    _peerLivenessFailures.clear();
    _peerRoutingStats.clear();
    _fileTransferAssemblies.clear();
    _peerCount = 0;
    _peerCountController.add(_peerCount);

    await _transport.stop();
    await _discovery.stop();

    _setHealth(RuntimeHealth.idle);
    _logger?.info(
      'runtime_stopped',
      scope: 'runtime',
      fields: {'nodeId': _localNodeId},
    );
  }

  void _setHealth(RuntimeHealth value) {
    if (_health == value) {
      return;
    }
    _health = value;
    _healthController.add(value);
  }

  void _updateTelemetry(
    RuntimeTelemetry Function(RuntimeTelemetry current) map,
  ) {
    _telemetry = map(_telemetry);
    _telemetryController.add(_telemetry);
  }

  Future<void> _flushPendingOutboundBundlesLocked() async {
    if (!_started || _peers.isEmpty || _isForwarding) {
      return;
    }

    final RuntimeHealth previousHealth = _health;
    _setHealth(RuntimeHealth.forwarding);
    _isForwarding = true;
    try {
      final now = DateTime.now();
      final List<DiscoveredPeer> peers = _peers.values.toList(growable: false);
      final pending = await _bundles.getPendingBundles();
      final outbound = pending
          .where((bundle) => bundle.sourceNodeId == _localNodeId)
          .toList(growable: false);

      if (outbound.isEmpty) {
        return;
      }

      for (var i = 0; i < outbound.length; i++) {
        final bundle = outbound[i];
        if (bundle.isExpired) {
          await _bundles.markRejected(
            bundle.bundleId,
            reason: 'Bundle expired before forwarding (TTL exceeded).',
          );
          continue;
        }
        if (bundle.hopCount >= maxHopCount) {
          await _bundles.markRejected(
            bundle.bundleId,
            reason: 'Bundle exceeded max hop count ($maxHopCount).',
          );
          continue;
        }
        if (bundle.failedAttempts >= maxSendAttempts) {
          await _bundles.markRejected(
            bundle.bundleId,
            reason: 'Bundle exceeded max send attempts ($maxSendAttempts).',
          );
          continue;
        }
        if (!_isReadyForRetry(bundle, now)) {
          continue;
        }

        final peer = _pickTargetPeer(bundle, peers);
        if (peer == null) {
          continue;
        }

        final nextHopBundle = bundle.copyWith(hopCount: bundle.hopCount + 1);

        try {
          _updateTelemetry(
            (t) => t.copyWith(outboundSendAttempts: t.outboundSendAttempts + 1),
          );
          await _transport.sendBundle(
            peerNodeId: peer.nodeId,
            bundle: nextHopBundle,
          );
          _logger?.info(
            'bundle_sent',
            scope: 'runtime',
            fields: {
              'bundleId': bundle.bundleId,
              'type': bundle.type,
              'peerNodeId': peer.nodeId,
            },
          );
          _recordPeerSendSuccess(peer.nodeId);
          _updateTelemetry(
            (t) =>
                t.copyWith(outboundSendSuccesses: t.outboundSendSuccesses + 1),
          );
          await _bundles.save(nextHopBundle);
          if (bundle.isAck) {
            await _bundles.markAcknowledged(bundle.bundleId);
          } else {
            await _bundles.markSent(bundle.bundleId);
          }
        } catch (error) {
          _logger?.warning(
            'bundle_send_failed',
            scope: 'runtime',
            fields: {
              'bundleId': bundle.bundleId,
              'type': bundle.type,
              'peerNodeId': peer.nodeId,
              'error': error.toString(),
            },
          );
          _recordPeerSendFailure(peer.nodeId);
          _updateTelemetry(
            (t) => t.copyWith(outboundSendFailures: t.outboundSendFailures + 1),
          );
          await _bundles.markSendFailed(
            bundle.bundleId,
            errorMessage: error.toString(),
          );
          // Keep the bundle pending for retry on next cycle.
        }
      }
    } finally {
      _isForwarding = false;
      _setHealth(_peers.isEmpty ? RuntimeHealth.discovering : previousHealth);
    }
  }

  Future<void> _runPeerLivenessChecks() async {
    if (!_started || _isForwarding) {
      return;
    }
    if (_peers.isEmpty) {
      _setHealth(RuntimeHealth.discovering);
      return;
    }

    var aliveCount = 0;
    final now = DateTime.now();
    final peers = _peers.values.toList(growable: false);
    for (final peer in peers) {
      _updateTelemetry((t) => t.copyWith(livenessChecks: t.livenessChecks + 1));
      final isAlive = await _transport.isPeerAlive(peerNodeId: peer.nodeId);
      if (isAlive) {
        aliveCount++;
        _peerSeenAt[peer.nodeId] = now;
        _peerLivenessFailures[peer.nodeId] = 0;
        continue;
      }

      _updateTelemetry(
        (t) => t.copyWith(livenessFailures: t.livenessFailures + 1),
      );

      final int failures = (_peerLivenessFailures[peer.nodeId] ?? 0) + 1;
      _peerLivenessFailures[peer.nodeId] = failures;

      final DateTime? lastSeen = _peerSeenAt[peer.nodeId];
      final bool isStale =
          lastSeen != null && now.difference(lastSeen) >= peerStaleAfter;
      if (isStale && failures >= peerLivenessFailureThreshold) {
        _updateTelemetry(
          (t) => t.copyWith(stalePeerRemovals: t.stalePeerRemovals + 1),
        );
        _removePeer(peer.nodeId);
      }
    }

    if (_peers.isEmpty) {
      _setHealth(RuntimeHealth.discovering);
      return;
    }

    _setHealth(
      aliveCount > 0 ? RuntimeHealth.connected : RuntimeHealth.degraded,
    );
  }

  void _handleDiscoveredPeer(DiscoveredPeer peer) {
    _updateTelemetry((t) => t.copyWith(discoveryEvents: t.discoveryEvents + 1));
    final now = DateTime.now();
    final DiscoveredPeer normalizedPeer = DiscoveredPeer(
      nodeId: peer.nodeId,
      host: peer.host,
      port: peer.port,
      lastSeen: now,
    );

    final previous = _peers[peer.nodeId];
    _peers[peer.nodeId] = normalizedPeer;
    _peerSeenAt[peer.nodeId] = now;
    _peerLivenessFailures[peer.nodeId] = 0;
    _peerRoutingStats.putIfAbsent(peer.nodeId, _PeerRoutingStats.new);

    final bool isDuplicate =
        previous != null &&
        previous.host == normalizedPeer.host &&
        previous.port == normalizedPeer.port;
    if (isDuplicate) {
      final DateTime? lastUpsertAt = _peerLastUpsertAt[peer.nodeId];
      if (lastUpsertAt != null &&
          now.difference(lastUpsertAt) < duplicatePeerSuppressionWindow) {
        _updateTelemetry(
          (t) => t.copyWith(
            duplicatePeerSuppressions: t.duplicatePeerSuppressions + 1,
          ),
        );
        return;
      }
    }

    _transport.registerPeer(normalizedPeer);
    _logger?.info(
      'peer_discovered',
      scope: 'runtime',
      fields: {
        'peerNodeId': normalizedPeer.nodeId,
        'host': normalizedPeer.host,
        'port': normalizedPeer.port,
      },
    );
    _peerLastUpsertAt[peer.nodeId] = now;

    unawaited(
      _peerRepository.upsertPeer(
        PeerContact(
          nodeId: normalizedPeer.nodeId,
          host: normalizedPeer.host,
          port: normalizedPeer.port,
          lastSeen: normalizedPeer.lastSeen,
        ),
      ),
    );
    _updateTelemetry((t) => t.copyWith(peerUpserts: t.peerUpserts + 1));

    _peerCount = _peers.length;
    _peerCountController.add(_peerCount);
    _setHealth(
      _peerCount > 0 ? RuntimeHealth.connected : RuntimeHealth.discovering,
    );
  }

  void _removePeer(String nodeId) {
    final removed = _peers.remove(nodeId);
    if (removed == null) {
      return;
    }

    _logger?.warning(
      'peer_removed',
      scope: 'runtime',
      fields: {'peerNodeId': nodeId},
    );

    _peerSeenAt.remove(nodeId);
    _peerLastUpsertAt.remove(nodeId);
    _peerLivenessFailures.remove(nodeId);
    _peerRoutingStats.remove(nodeId);

    _peerCount = _peers.length;
    _peerCountController.add(_peerCount);
  }

  DiscoveredPeer? _pickTargetPeer(Bundle bundle, List<DiscoveredPeer> peers) {
    final destinationId = bundle.destinationNodeId;
    if (destinationId != null) {
      final directPeer = _peers[destinationId];
      if (directPeer != null) {
        return directPeer;
      }
      final relayPeers = _rankPeersForBundle(
        bundle,
        _pickRelayPeers(bundle, peers),
      );
      if (relayPeers.isEmpty) {
        return null;
      }
      return relayPeers.first;
    }
    if (peers.isEmpty) {
      return null;
    }
    final rankedPeers = _rankPeersForBundle(
      bundle,
      _pickRelayPeers(bundle, peers),
    );
    if (rankedPeers.isEmpty) {
      return null;
    }
    return rankedPeers.first;
  }

  List<DiscoveredPeer> _pickRelayPeers(
    Bundle bundle,
    List<DiscoveredPeer> peers,
  ) {
    if (peers.isEmpty) {
      return const <DiscoveredPeer>[];
    }

    final String sourceNodeId = bundle.sourceNodeId;
    final String? destinationNodeId = bundle.destinationNodeId;

    return peers
        .where(
          (peer) =>
              peer.nodeId != sourceNodeId &&
              (destinationNodeId == null || peer.nodeId != destinationNodeId),
        )
        .toList(growable: false);
  }

  List<DiscoveredPeer> _rankPeersForBundle(
    Bundle bundle,
    List<DiscoveredPeer> peers,
  ) {
    final now = DateTime.now();
    final sorted = peers.toList(growable: false)
      ..sort((a, b) {
        final scoreA = _scorePeerForBundle(bundle, a, now);
        final scoreB = _scorePeerForBundle(bundle, b, now);
        final byScore = scoreB.compareTo(scoreA);
        if (byScore != 0) {
          return byScore;
        }
        return a.nodeId.compareTo(b.nodeId);
      });
    return sorted;
  }

  int _scorePeerForBundle(Bundle bundle, DiscoveredPeer peer, DateTime now) {
    final stats = _peerRoutingStats[peer.nodeId] ?? const _PeerRoutingStats();
    final lastSeen = _peerSeenAt[peer.nodeId] ?? peer.lastSeen;
    final secondsSinceSeen = now.difference(lastSeen).inSeconds;
    final recencyScore = (100 - secondsSinceSeen).clamp(0, 100);
    final successScore = stats.successCount * 8;
    final failurePenalty = stats.failureCount * 6;
    final streakPenalty = stats.consecutiveFailures * 15;
    final recentFailurePenalty =
        stats.lastFailureAt != null &&
            now.difference(stats.lastFailureAt!).inSeconds < 20
        ? 80
        : 0;

    final priorityWeight = switch (bundle.priority) {
      BundlePriority.critical => 3,
      BundlePriority.high => 2,
      BundlePriority.normal => 1,
      BundlePriority.low => 1,
    };

    final reliability =
        (successScore * priorityWeight) -
        ((failurePenalty + streakPenalty + recentFailurePenalty) *
            priorityWeight);

    return recencyScore + reliability;
  }

  int _relayFanoutFor(BundlePriority priority) {
    return switch (priority) {
      BundlePriority.low => 1,
      BundlePriority.normal => 1,
      BundlePriority.high => 2,
      BundlePriority.critical => 3,
    };
  }

  void _recordPeerSendSuccess(String peerNodeId) {
    final previous = _peerRoutingStats[peerNodeId] ?? const _PeerRoutingStats();
    _peerRoutingStats[peerNodeId] = previous.copyWith(
      successCount: previous.successCount + 1,
      consecutiveFailures: 0,
      lastSuccessAt: DateTime.now(),
    );
  }

  void _recordPeerSendFailure(String peerNodeId) {
    final previous = _peerRoutingStats[peerNodeId] ?? const _PeerRoutingStats();
    _peerRoutingStats[peerNodeId] = previous.copyWith(
      failureCount: previous.failureCount + 1,
      consecutiveFailures: previous.consecutiveFailures + 1,
      lastFailureAt: DateTime.now(),
    );
  }

  Future<void> _handleIncomingBundle(Bundle bundle) async {
    final isValid = await _bundleSignatureService.verify(bundle);
    if (!isValid) {
      _logger?.warning(
        'bundle_rejected_invalid_signature',
        scope: 'runtime',
        fields: {
          'bundleId': bundle.bundleId,
          'type': bundle.type,
          'sourceNodeId': bundle.sourceNodeId,
        },
      );
      await _bundles.markRejected(
        bundle.bundleId,
        reason: 'Invalid or missing bundle signature.',
      );
      return;
    }

    final existingBundle = await _bundles.getById(bundle.bundleId);
    if (existingBundle != null &&
        existingBundle.signature == bundle.signature &&
        existingBundle.sourcePublicKey == bundle.sourcePublicKey) {
      _logger?.warning(
        'bundle_replay_detected',
        scope: 'runtime',
        fields: {
          'bundleId': bundle.bundleId,
          'type': bundle.type,
          'sourceNodeId': bundle.sourceNodeId,
        },
      );
      return;
    }

    _logger?.info(
      'bundle_received',
      scope: 'runtime',
      fields: {
        'bundleId': bundle.bundleId,
        'type': bundle.type,
        'sourceNodeId': bundle.sourceNodeId,
      },
    );
    _updateTelemetry(
      (t) => t.copyWith(inboundBundlesReceived: t.inboundBundlesReceived + 1),
    );
    await _bundles.save(bundle);

    if (bundle.isExpired || bundle.hopCount > maxHopCount) {
      await _bundles.markAcknowledged(bundle.bundleId);
      return;
    }

    if (bundle.destinationNodeId != null &&
        bundle.destinationNodeId != _localNodeId &&
        !bundle.isAck &&
        !bundle.isSyncRejection) {
      await _forwardInboundBundle(bundle);
      return;
    }

    await _routeInboundBundle(bundle);
  }

  Future<void> _forwardInboundBundle(Bundle bundle) async {
    if (bundle.hopCount >= maxHopCount) {
      await _bundles.markRejected(
        bundle.bundleId,
        reason: 'Bundle exceeded max hop count ($maxHopCount) while relaying.',
      );
      return;
    }

    if (bundle.isExpired) {
      await _bundles.markRejected(
        bundle.bundleId,
        reason: 'Bundle expired before relaying (TTL exceeded).',
      );
      return;
    }

    final List<DiscoveredPeer> peers = _peers.values.toList(growable: false);
    final DiscoveredPeer? directTarget = bundle.destinationNodeId == null
        ? null
        : _peers[bundle.destinationNodeId!];

    final List<DiscoveredPeer> rankedRelays = _rankPeersForBundle(
      bundle,
      _pickRelayPeers(bundle, peers),
    );
    final int fanout = _relayFanoutFor(bundle.priority);

    final List<DiscoveredPeer> relayTargets = <DiscoveredPeer>[
      ...directTarget == null
          ? const <DiscoveredPeer>[]
          : <DiscoveredPeer>[directTarget],
      ...rankedRelays
          .where(
            (peer) =>
                directTarget == null || peer.nodeId != directTarget.nodeId,
          )
          .take(fanout),
    ];

    if (relayTargets.isEmpty) {
      return;
    }

    final Bundle relayedBundle = bundle.copyWith(hopCount: bundle.hopCount + 1);

    for (final peer in relayTargets) {
      try {
        await _transport.sendBundle(
          peerNodeId: peer.nodeId,
          bundle: relayedBundle,
        );
        _recordPeerSendSuccess(peer.nodeId);
        _updateTelemetry(
          (t) => t.copyWith(inboundBundlesRelayed: t.inboundBundlesRelayed + 1),
        );
      } catch (_) {
        _recordPeerSendFailure(peer.nodeId);
        // Opportunistic relay: ignore individual peer send failures.
      }
    }

    await _bundles.markAcknowledged(bundle.bundleId);
  }

  Future<void> _routeInboundBundle(Bundle bundle) {
    if (bundle.isAck) {
      return _handleInboundAck(bundle);
    }
    if (bundle.isSyncRejection) {
      return _handleInboundSyncRejection(bundle);
    }
    if (bundle.type == Bundle.typeFileShareMetadata) {
      return _handleInboundFileShareMetadata(bundle);
    }
    if (bundle.type == Bundle.typeFileShareChunk) {
      return _handleInboundFileShareChunk(bundle);
    }
    return _handleInboundAppBundle(bundle);
  }

  Future<void> _handleInboundFileShareMetadata(Bundle bundle) async {
    await _bundles.markAcknowledged(bundle.bundleId);

    final String? contentHash = bundle.payloadReference;
    final Map<String, Object?>? manifest = _decodeObjectPayload(bundle.payload);
    if (contentHash == null || contentHash.isEmpty || manifest == null) {
      await _enqueueAckBundleFor(bundle);
      return;
    }

    _fileTransferAssemblies.putIfAbsent(
      contentHash,
      () => _FileTransferAssembly(
        contentHash: contentHash,
        fileName: manifest['fileName'] as String? ?? 'offlimu-file',
        mimeType: manifest['mimeType'] as String?,
        totalBytes: (manifest['sizeBytes'] as num?)?.toInt() ?? 0,
        chunkCount: (manifest['chunkCount'] as num?)?.toInt(),
        chunkSizeBytes: (manifest['chunkSizeBytes'] as num?)?.toInt(),
      ),
    );

    await _enqueueAckBundleFor(bundle);
  }

  Future<void> _handleInboundFileShareChunk(Bundle bundle) async {
    final String? contentHash = bundle.payloadReference;
    final Map<String, Object?>? chunk = _decodeObjectPayload(bundle.payload);
    if (contentHash == null || contentHash.isEmpty || chunk == null) {
      await _bundles.markRejected(
        bundle.bundleId,
        reason: 'Malformed file chunk payload.',
      );
      return;
    }

    final _FileTransferAssembly assembly = _fileTransferAssemblies.putIfAbsent(
      contentHash,
      () => _FileTransferAssembly(
        contentHash: contentHash,
        fileName: chunk['fileName'] as String? ?? 'offlimu-file',
        mimeType: chunk['mimeType'] as String?,
        totalBytes: (chunk['totalBytes'] as num?)?.toInt() ?? 0,
        chunkCount: (chunk['chunkCount'] as num?)?.toInt(),
        chunkSizeBytes: (chunk['chunkSizeBytes'] as num?)?.toInt(),
      ),
    );

    final int? chunkIndex = (chunk['chunkIndex'] as num?)?.toInt();
    final String? chunkBytesBase64 = chunk['chunkBytesBase64'] as String?;
    if (chunkIndex == null || chunkBytesBase64 == null) {
      await _bundles.markRejected(
        bundle.bundleId,
        reason: 'File chunk missing index or bytes.',
      );
      return;
    }

    assembly.addChunk(chunkIndex, base64Decode(chunkBytesBase64));

    if (assembly.isComplete) {
      final Uint8List assembledBytes = assembly.assemble();
      final String digest = sha256.convert(assembledBytes).toString();
      final String verifiedContentHash = 'sha256:$digest';
      if (verifiedContentHash != contentHash) {
        _fileTransferAssemblies.remove(contentHash);
        await _bundles.markRejected(
          bundle.bundleId,
          reason: 'File chunk hash mismatch.',
        );
        return;
      }

      try {
        final String? localPath = await _contentStore.put(
          contentHash: contentHash,
          bytes: assembledBytes,
        );
        await _bundles.saveContentMetadata(
          ContentMetadataRecord(
            contentHash: contentHash,
            mimeType: assembly.mimeType,
            totalBytes: assembledBytes.length,
            chunkCount: assembly.chunkCountValue,
            createdAt: DateTime.now(),
            localPath: localPath,
          ),
        );
        _fileTransferAssemblies.remove(contentHash);
      } on ContentStoreQuotaExceededException {
        _fileTransferAssemblies.remove(contentHash);
        await _bundles.markRejected(
          bundle.bundleId,
          reason: 'Storage quota exceeded while saving received file.',
        );
        return;
      }
    }

    await _enqueueAckBundleFor(bundle);
  }

  Map<String, Object?>? _decodeObjectPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final Object? parsed = jsonDecode(payload);
      if (parsed is! Map) {
        return null;
      }
      return parsed.cast<String, Object?>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleInboundAck(Bundle ack) async {
    _logger?.info(
      'ack_received',
      scope: 'runtime',
      fields: {
        'ackBundleId': ack.bundleId,
        'ackForBundleId': ack.ackForBundleId,
      },
    );
    _updateTelemetry(
      (t) => t.copyWith(inboundAcksReceived: t.inboundAcksReceived + 1),
    );
    await _bundles.recordAckReceipt(ack);
    await _bundles.markAcknowledged(ack.bundleId);
    final String? ackForBundleId = ack.ackForBundleId;
    if (ackForBundleId != null) {
      await _bundles.markAcknowledged(ackForBundleId);
    }
  }

  Future<void> _handleInboundSyncRejection(Bundle rejection) async {
    await _bundles.markAcknowledged(rejection.bundleId);
    final rejectedBundleId = rejection.ackForBundleId;
    if (rejectedBundleId != null) {
      await _bundles.markRejected(
        rejectedBundleId,
        reason: rejection.payload ?? 'Rejected by remote peer',
      );
    }
  }

  Future<void> _handleInboundAppBundle(Bundle bundle) async {
    await _bundles.markAcknowledged(bundle.bundleId);
    await _enqueueAckBundleFor(bundle);
  }

  bool _isReadyForRetry(Bundle bundle, DateTime now) {
    if (bundle.failedAttempts == 0) {
      return true;
    }
    final DateTime lastAttemptAt = bundle.sentAt ?? bundle.createdAt;
    final Duration delay = _retryDelay(bundle.failedAttempts);
    final DateTime nextAttemptAt = lastAttemptAt.add(delay);
    return !now.isBefore(nextAttemptAt);
  }

  Duration _retryDelay(int failedAttempts) {
    if (failedAttempts <= 0) {
      return Duration.zero;
    }
    final multiplier = 1 << (failedAttempts - 1);
    final seconds = retryBaseDelay.inSeconds * multiplier;
    final cappedSeconds = seconds > maxRetryDelay.inSeconds
        ? maxRetryDelay.inSeconds
        : seconds;
    return Duration(seconds: cappedSeconds);
  }

  Future<void> _enqueueAckBundleFor(Bundle inbound) async {
    _updateTelemetry(
      (t) => t.copyWith(outboundAcksGenerated: t.outboundAcksGenerated + 1),
    );
    final Bundle ack = Bundle(
      bundleId:
          'ack-${inbound.bundleId}-${DateTime.now().microsecondsSinceEpoch}',
      type: Bundle.typeAck,
      sourceNodeId: _localNodeId,
      destinationNodeId: inbound.sourceNodeId,
      ackForBundleId: inbound.bundleId,
      createdAt: DateTime.now(),
      ttlSeconds: 300,
    );

    final Bundle signedAck = await _bundleSignatureService.sign(
      bundle: ack,
      nodeId: _localNodeId,
    );

    await _bundles.save(signedAck);
    final targetPeer = _peers[inbound.sourceNodeId];
    if (targetPeer == null) {
      return;
    }

    try {
      await _transport.sendBundle(
        peerNodeId: targetPeer.nodeId,
        bundle: signedAck,
      );
      _recordPeerSendSuccess(targetPeer.nodeId);
      await _bundles.markAcknowledged(signedAck.bundleId);
    } catch (_) {
      _recordPeerSendFailure(targetPeer.nodeId);
      // Keep ACK pending for retry in periodic flush.
    }
  }
}

class _PeerRoutingStats {
  const _PeerRoutingStats({
    this.successCount = 0,
    this.failureCount = 0,
    this.consecutiveFailures = 0,
    this.lastSuccessAt,
    this.lastFailureAt,
  });

  final int successCount;
  final int failureCount;
  final int consecutiveFailures;
  final DateTime? lastSuccessAt;
  final DateTime? lastFailureAt;

  _PeerRoutingStats copyWith({
    int? successCount,
    int? failureCount,
    int? consecutiveFailures,
    DateTime? lastSuccessAt,
    DateTime? lastFailureAt,
  }) {
    return _PeerRoutingStats(
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastFailureAt: lastFailureAt ?? this.lastFailureAt,
    );
  }
}

class _FileTransferAssembly {
  _FileTransferAssembly({
    required this.contentHash,
    required this.fileName,
    required this.mimeType,
    required this.totalBytes,
    required this.chunkCount,
    required this.chunkSizeBytes,
  });

  final String contentHash;
  final String fileName;
  final String? mimeType;
  final int totalBytes;
  final int? chunkCount;
  final int? chunkSizeBytes;
  final Map<int, Uint8List> _chunks = <int, Uint8List>{};

  void addChunk(int index, Uint8List bytes) {
    _chunks[index] = bytes;
  }

  bool get isComplete {
    if (chunkCount == null) {
      return false;
    }
    return _chunks.length >= chunkCount!;
  }

  int get chunkCountValue => chunkCount ?? _chunks.length;

  Uint8List assemble() {
    final List<int> data = <int>[];
    final int expectedChunks = chunkCount ?? _chunks.length;
    for (var index = 0; index < expectedChunks; index++) {
      final Uint8List? chunk = _chunks[index];
      if (chunk == null) {
        throw StateError('Missing file chunk at index $index.');
      }
      data.addAll(chunk);
    }
    return Uint8List.fromList(data);
  }
}
