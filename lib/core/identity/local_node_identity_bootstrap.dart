import 'package:offlimu/domain/entities/node_identity.dart';
import 'package:offlimu/infrastructure/identity/secure_node_identity_store.dart';

NodeIdentity? _bootstrappedLocalNodeIdentity;

Future<NodeIdentity> bootstrapLocalNodeIdentity({
  String displayName = 'OffLiMU Node',
  SecureNodeIdentityStore? store,
}) async {
  final resolvedStore = store ?? SecureNodeIdentityStore();
  final publicIdentity = await resolvedStore.loadOrCreate(displayName: displayName);
  final localIdentity = NodeIdentity(
    nodeId: publicIdentity.nodeId,
    displayName: publicIdentity.displayName,
  );
  _bootstrappedLocalNodeIdentity = localIdentity;
  return localIdentity;
}

NodeIdentity resolveLocalNodeIdentity({
  required String fallbackNodeId,
  String displayName = 'OffLiMU Node',
}) {
  return _bootstrappedLocalNodeIdentity ?? NodeIdentity(
    nodeId: fallbackNodeId,
    displayName: displayName,
  );
}
