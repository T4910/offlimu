import 'package:offlimu/domain/entities/node_public_identity.dart';

abstract interface class NodeIdentityStore {
  Future<NodePublicIdentity> loadOrCreate({
    required String nodeId,
    required String displayName,
  });

  Future<NodePublicIdentity> rotate({
    required String nodeId,
    required String displayName,
  });
}
