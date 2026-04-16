import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/services/discovery_adapter.dart';

abstract interface class TransportAdapter {
  Stream<Bundle> incomingBundles();
  void registerPeer(DiscoveredPeer peer);
  Future<bool> isPeerAlive({required String peerNodeId});
  Future<void> sendBundle({required String peerNodeId, required Bundle bundle});
  Future<void> start();
  Future<void> stop();
}
