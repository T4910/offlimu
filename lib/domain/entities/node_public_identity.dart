class NodePublicIdentity {
  const NodePublicIdentity({
    required this.nodeId,
    required this.displayName,
    required this.publicKeyBase64,
    required this.publicKeyFingerprint,
  });

  final String nodeId;
  final String displayName;
  final String publicKeyBase64;
  final String publicKeyFingerprint;
}