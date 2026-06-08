import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/use_cases/wallet_event_bundle_mapper.dart';
import 'package:offlimu/domain/use_cases/wallet_sync_reconciliation_service.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';
import 'package:offlimu/infrastructure/db/drift_wallet_repository.dart';
import 'package:offlimu/node_runtime/node_runtime.dart';
import 'package:offlimu/domain/services/transport_adapter.dart';
import 'package:offlimu/domain/services/discovery_adapter.dart';
import 'package:offlimu/domain/entities/peer_contact.dart' as domain;
import 'dart:typed_data';
import 'package:offlimu/domain/repositories/peer_repository.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';

class _FakeTransport implements TransportAdapter {
  final StreamController<Bundle> _controller =
      StreamController<Bundle>.broadcast();

  @override
  Stream<Bundle> incomingBundles() => _controller.stream;

  @override
  void registerPeer(peer) {}

  @override
  Future<bool> isPeerAlive({required String peerNodeId}) async => true;

  @override
  Future<void> sendBundle({
    required String peerNodeId,
    required Bundle bundle,
  }) async {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {
    await _controller.close();
  }

  void emit(Bundle bundle) => _controller.add(bundle);
}

class _FakeDiscovery implements DiscoveryAdapter {
  @override
  Stream<DiscoveredPeer> discover() async* {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class _FakePeerRepository implements PeerRepository {
  final StreamController<List<domain.PeerContact>> _controller =
      StreamController<List<domain.PeerContact>>.broadcast();

  @override
  Future<void> upsertPeer(domain.PeerContact peer) async {}

  @override
  Stream<List<domain.PeerContact>> watchPeers() => _controller.stream;
}

class _FakeContentStore implements ContentStore {
  @override
  Future<String?> put({
    required String contentHash,
    required Uint8List bytes,
  }) async => null;

  @override
  Future<Uint8List?> read({required String contentHash}) async => null;

  @override
  Future<void> delete({required String contentHash}) async {}

  @override
  Future<void> clear() async {}
}

class _PassThroughSignatureService implements BundleSignatureService {
  @override
  Future<Bundle> sign({required Bundle bundle, required String nodeId}) async =>
      bundle.copyWith(signature: 'signed-by-$nodeId');

  @override
  Future<bool> verify(Bundle bundle) async => true;
}

class _SpyWalletSyncService extends WalletSyncReconciliationService {
  final List<Bundle> calls = [];

  _SpyWalletSyncService({
    required DriftWalletRepository walletRepository,
    required WalletEventBundleMapper mapper,
  }) : super(walletRepository: walletRepository, mapper: mapper);

  @override
  Future<void> applyInboundWalletBundle(Bundle bundle) async {
    calls.add(bundle);
    await super.applyInboundWalletBundle(bundle);
  }
}

void main() {
  test(
    'NodeRuntime calls WalletSyncReconciliationService on transport-delivered wallet_spend',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final localNodeId = 'node-local-001';
      final bundleRepo = DriftBundleRepository(db, localNodeId: localNodeId);
      final walletRepo = DriftWalletRepository(db);
      final transport = _FakeTransport();
      final discovery = _FakeDiscovery();
      final peerRepo = _FakePeerRepository();
      final contentStore = _FakeContentStore();
      final signatureService = _PassThroughSignatureService();
      final mapper = WalletEventBundleMapper();

      final spyService = _SpyWalletSyncService(
        walletRepository: walletRepo,
        mapper: mapper,
      );

      final runtime = NodeRuntime(
        localNodeId: localNodeId,
        discovery: discovery,
        transport: transport,
        bundles: bundleRepo,
        peers: peerRepo,
        contentStore: contentStore,
        bundleSignatureService: signatureService,
        walletSyncReconciliationService: spyService,
      );

      await runtime.start();

      final spend = mapper.toSpendBundle(
        bundleId: 'spend-rt-1',
        localNodeId: 'node-remote-123',
        recipientNodeId: localNodeId,
        amountMinorUnits: 300,
        createdAt: DateTime.now(),
      );

      transport.emit(spend);

      // Give runtime a moment to process the incoming bundle.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(spyService.calls, isNotEmpty);
      expect(spyService.calls.single.bundleId, spend.bundleId);

      final saved = await bundleRepo.getById(spend.bundleId);
      expect(saved, isNotNull);

      await runtime.stop();
    },
  );
}
