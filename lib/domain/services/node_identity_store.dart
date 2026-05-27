import 'package:offlimu/domain/entities/node_public_identity.dart';

abstract interface class NodeIdentityStore {
  Future<NodePublicIdentity> loadOrCreate({
    required String displayName,
  });

  Future<NodePublicIdentity> rotate({
    required String displayName,
  });
}
