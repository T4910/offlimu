import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/entities/peer_contact.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/peer_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/services/discovery_adapter.dart';
import 'package:offlimu/domain/services/transport_adapter.dart';
import 'package:offlimu/node_runtime/node_runtime.dart';
import 'package:offlimu/node_runtime/node_runtime_state.dart';

void main() {
  test('start and stop are serialized by orchestration queue', () async {
    final fakeDiscovery = _FakeDiscoveryAdapter();
    final fakeTransport = _FakeTransportAdapter();
    final runtime = NodeRuntime(
      localNodeId: 'node-a',
      discovery: fakeDiscovery,
      transport: fakeTransport,
      bundles: _FakeBundleRepository(),
      peers: _FakePeerRepository(),
      contentStore: _FakeContentStore(),
      bundleSignatureService: _FakeBundleSignatureService(),
    );

    final startFuture = runtime.start();
    final stopFuture = runtime.stop();

    await Future<void>.delayed(Duration.zero);
    fakeTransport.releaseStart();

    await Future.wait(<Future<void>>[startFuture, stopFuture]);

    expect(runtime.isRunning, isFalse);
    expect(runtime.health, RuntimeHealth.idle);
    expect(
      fakeTransport.events,
      containsAllInOrder(<String>['transport.start', 'transport.stop']),
    );
    expect(fakeDiscovery.events, contains('discovery.stop'));

    await runtime.dispose();
  });

  test('runtime emits expected start-stop health transitions', () async {
    final fakeDiscovery = _FakeDiscoveryAdapter();
    final fakeTransport = _FakeTransportAdapter();
    final runtime = NodeRuntime(
      localNodeId: 'node-a',
      discovery: fakeDiscovery,
      transport: fakeTransport,
      bundles: _FakeBundleRepository(),
      peers: _FakePeerRepository(),
      contentStore: _FakeContentStore(),
      bundleSignatureService: _FakeBundleSignatureService(),
    );

    final emitted = <RuntimeHealth>[];
    final sub = runtime.healthStream.listen(emitted.add);
    addTearDown(() async {
      await sub.cancel();
      await runtime.dispose();
    });

    final startFuture = runtime.start();
    await Future<void>.delayed(Duration.zero);
    fakeTransport.releaseStart();
    await startFuture;

    await runtime.stop();

    expect(emitted, contains(RuntimeHealth.starting));
    expect(emitted, contains(RuntimeHealth.discovering));
    expect(emitted, contains(RuntimeHealth.stopping));
    expect(emitted.last, RuntimeHealth.idle);
  });

  test('runtime rejects inbound bundles with invalid signatures', () async {
    final fakeDiscovery = _FakeDiscoveryAdapter();
    final fakeTransport = _FakeTransportAdapter();
    final fakeBundles = _FakeBundleRepository();
    final runtime = NodeRuntime(
      localNodeId: 'node-a',
      discovery: fakeDiscovery,
      transport: fakeTransport,
      bundles: fakeBundles,
      peers: _FakePeerRepository(),
      contentStore: _FakeContentStore(),
      bundleSignatureService: _FakeBundleSignatureService(verifyResult: false),
    );

    final startFuture = runtime.start();
    await Future<void>.delayed(Duration.zero);
    fakeTransport.releaseStart();
    await startFuture;

    fakeTransport.emitIncoming(
      Bundle(
        bundleId: 'tampered-1',
        type: Bundle.typeChatMessage,
        sourceNodeId: 'node-b',
        destinationNodeId: 'node-a',
        payload: 'tampered',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000007000),
        ttlSeconds: 3600,
        signature: 'invalid-signature',
        sourcePublicKey: 'invalid-public-key',
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(fakeBundles.rejectedBundles, contains('tampered-1'));

    await runtime.stop();
    await runtime.dispose();
  });

  test('runtime ignores replayed bundles already stored', () async {
    final replayBundle = Bundle(
      bundleId: 'replay-1',
      type: Bundle.typeChatMessage,
      sourceNodeId: 'node-b',
      destinationNodeId: 'node-a',
      payload: 'hello again',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000008000),
      ttlSeconds: 3600,
      signature: 'signature-1',
      sourcePublicKey: 'public-key-1',
    );

    final fakeDiscovery = _FakeDiscoveryAdapter();
    final fakeTransport = _FakeTransportAdapter();
    final fakeBundles = _FakeBundleRepository(
      existingBundlesById: <String, Bundle>{
        replayBundle.bundleId: replayBundle,
      },
    );
    final runtime = NodeRuntime(
      localNodeId: 'node-a',
      discovery: fakeDiscovery,
      transport: fakeTransport,
      bundles: fakeBundles,
      peers: _FakePeerRepository(),
      contentStore: _FakeContentStore(),
      bundleSignatureService: _FakeBundleSignatureService(),
    );

    final startFuture = runtime.start();
    await Future<void>.delayed(Duration.zero);
    fakeTransport.releaseStart();
    await startFuture;

    fakeTransport.emitIncoming(replayBundle);
    await Future<void>.delayed(Duration.zero);

    expect(fakeBundles.savedBundles, isEmpty);
    expect(fakeBundles.rejectedBundles, isEmpty);

    await runtime.stop();
    await runtime.dispose();
  });

  test(
    'runtime signs outbound ACK bundles before saving and sending',
    () async {
      final now = DateTime.now();
      final inboundBundle = Bundle(
        bundleId: 'chat-ack-1',
        type: Bundle.typeChatMessage,
        sourceNodeId: 'node-b',
        destinationNodeId: 'node-a',
        payload: 'hello',
        createdAt: now,
        ttlSeconds: 3600,
        signature: 'signature-1',
        sourcePublicKey: 'public-key-1',
      );

      final fakeDiscovery = _FakeDiscoveryAdapter();
      final fakeTransport = _FakeTransportAdapter();
      final fakeBundles = _FakeBundleRepository();
      final fakeSignatureService = _FakeBundleSignatureService(
        signResultBuilder: (Bundle bundle, String nodeId) {
          return bundle.copyWith(
            sourcePublicKey: 'public-key-$nodeId',
            signature: 'signed-${bundle.bundleId}',
          );
        },
      );
      final runtime = NodeRuntime(
        localNodeId: 'node-a',
        discovery: fakeDiscovery,
        transport: fakeTransport,
        bundles: fakeBundles,
        peers: _FakePeerRepository(),
        contentStore: _FakeContentStore(),
        bundleSignatureService: fakeSignatureService,
      );

      final startFuture = runtime.start();
      await Future<void>.delayed(Duration.zero);
      fakeTransport.releaseStart();
      await startFuture;

      fakeDiscovery.emit(
        DiscoveredPeer(
          nodeId: 'node-b',
          host: '192.168.1.20',
          port: 4040,
          lastSeen: now,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      fakeTransport.emitIncoming(inboundBundle);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(fakeSignatureService.signCalls, hasLength(1));
      expect(fakeSignatureService.signCalls.single.bundle.type, Bundle.typeAck);
      expect(fakeSignatureService.signCalls.single.nodeId, 'node-a');
      expect(fakeBundles.savedBundles, hasLength(2));
      expect(
        fakeBundles.savedBundles.where((bundle) => bundle.type == Bundle.typeAck),
        hasLength(1),
      );
      final Bundle savedAck = fakeBundles.savedBundles
          .lastWhere((bundle) => bundle.type == Bundle.typeAck);
      expect(savedAck.signature, isNotNull);
      expect(savedAck.sourcePublicKey, isNotNull);
      expect(savedAck.ackForBundleId, 'chat-ack-1');
      expect(fakeTransport.sentBundles, hasLength(1));
      expect(fakeTransport.sentBundles.single.bundle.type, Bundle.typeAck);
      expect(fakeTransport.sentBundles.single.bundle.signature, isNotNull);
      expect(
        fakeTransport.sentBundles.single.bundle.sourcePublicKey,
        isNotNull,
      );
      expect(
        fakeTransport.sentBundles.single.bundle.ackForBundleId,
        'chat-ack-1',
      );

      await runtime.stop();
      await runtime.dispose();
    },
  );
}

class _FakeDiscoveryAdapter implements DiscoveryAdapter {
  final StreamController<DiscoveredPeer> _controller =
      StreamController<DiscoveredPeer>.broadcast();
  final List<String> events = <String>[];

  @override
  Stream<DiscoveredPeer> discover() => _controller.stream;

  void emit(DiscoveredPeer peer) {
    _controller.add(peer);
  }

  @override
  Future<void> start() async {
    events.add('discovery.start');
  }

  @override
  Future<void> stop() async {
    events.add('discovery.stop');
    await _controller.close();
  }
}

class _FakeTransportAdapter implements TransportAdapter {
  final StreamController<Bundle> _controller =
      StreamController<Bundle>.broadcast();
  final List<String> events = <String>[];
  final List<_SentBundleRecord> sentBundles = <_SentBundleRecord>[];
  final Completer<void> allowStart = Completer<void>();

  bool _startReleased = false;

  @override
  Stream<Bundle> incomingBundles() => _controller.stream;

  void emitIncoming(Bundle bundle) {
    _controller.add(bundle);
  }

  @override
  void registerPeer(DiscoveredPeer peer) {}

  @override
  Future<bool> isPeerAlive({required String peerNodeId}) async => true;

  @override
  Future<void> sendBundle({
    required String peerNodeId,
    required Bundle bundle,
  }) async {
    sentBundles.add(_SentBundleRecord(peerNodeId: peerNodeId, bundle: bundle));
  }

  @override
  Future<void> start() async {
    events.add('transport.start');
    await allowStart.future;
  }

  void releaseStart() {
    if (_startReleased) {
      return;
    }
    _startReleased = true;
    if (!allowStart.isCompleted) {
      allowStart.complete();
    }
  }

  @override
  Future<void> stop() async {
    events.add('transport.stop');
    await _controller.close();
  }
}

class _FakeContentStore implements ContentStore {
  @override
  Future<String?> put({
    required String contentHash,
    required Uint8List bytes,
  }) async {
    return '/tmp/$contentHash';
  }

  @override
  Future<Uint8List?> read({required String contentHash}) async => null;
}

class _FakePeerRepository implements PeerRepository {
  @override
  Future<void> upsertPeer(PeerContact peer) async {}

  @override
  Stream<List<PeerContact>> watchPeers() {
    return const Stream<List<PeerContact>>.empty();
  }
}

class _FakeBundleRepository implements BundleRepository {
  _FakeBundleRepository({Map<String, Bundle>? existingBundlesById})
    : existingBundlesById = existingBundlesById ?? <String, Bundle>{};

  @override
  Future<void> saveContentMetadata(ContentMetadataRecord metadata) async {}

  @override
  Future<ContentMetadataRecord?> getContentMetadata(String contentHash) async =>
      null;

  @override
  Stream<List<ContentMetadataRecord>> watchRecentContentMetadata({
    int limit = 50,
  }) {
    return const Stream<List<ContentMetadataRecord>>.empty();
  }

  @override
  Future<void> markSent(String bundleId) async {}

  @override
  Future<void> markSendFailed(
    String bundleId, {
    required String errorMessage,
  }) async {}

  @override
  Future<void> markAcknowledged(String bundleId) async {}

  @override
  Future<bool> recordAckReceipt(Bundle ackBundle) async => false;

  @override
  Future<List<Bundle>> getPendingBundles() async => const <Bundle>[];

  @override
  Stream<List<Bundle>> watchPendingBundles() {
    return const Stream<List<Bundle>>.empty();
  }

  @override
  Stream<List<Bundle>> watchBundlesByType(String type) {
    return const Stream<List<Bundle>>.empty();
  }

  @override
  Stream<List<AckAuditEvent>> watchRecentAckEvents({int limit = 20}) {
    return const Stream<List<AckAuditEvent>>.empty();
  }

  final List<String> rejectedBundles = <String>[];
  final List<Bundle> savedBundles = <Bundle>[];
  final Map<String, Bundle> existingBundlesById;

  @override
  Future<void> save(Bundle bundle) async {
    savedBundles.add(bundle);
    existingBundlesById[bundle.bundleId] = bundle;
  }

  @override
  Future<void> markRejected(String bundleId, {required String reason}) async {
    rejectedBundles.add(bundleId);
  }

  @override
  Future<Bundle?> getById(String bundleId) async {
    return existingBundlesById[bundleId];
  }
}

class _FakeBundleSignatureService implements BundleSignatureService {
  _FakeBundleSignatureService({
    this.verifyResult = true,
    this.signResultBuilder,
  });

  final bool verifyResult;
  final Bundle Function(Bundle bundle, String nodeId)? signResultBuilder;
  final List<_SignCall> signCalls = <_SignCall>[];

  @override
  Future<Bundle> sign({required Bundle bundle, required String nodeId}) async {
    signCalls.add(_SignCall(bundle: bundle, nodeId: nodeId));
    return signResultBuilder?.call(bundle, nodeId) ?? bundle;
  }

  @override
  Future<bool> verify(Bundle bundle) async => verifyResult;
}

class _SignCall {
  const _SignCall({required this.bundle, required this.nodeId});

  final Bundle bundle;
  final String nodeId;
}

class _SentBundleRecord {
  const _SentBundleRecord({required this.peerNodeId, required this.bundle});

  final String peerNodeId;
  final Bundle bundle;
}
