import 'package:offlimu/domain/entities/peer_contact.dart';

abstract interface class PeerRepository {
  Future<void> upsertPeer(PeerContact peer);
  Stream<List<PeerContact>> watchPeers();
}
