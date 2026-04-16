abstract interface class DiscoveryAdapter {
  Stream<DiscoveredPeer> discover();
  Future<void> start();
  Future<void> stop();
}

class DiscoveredPeer {
  const DiscoveredPeer({
    required this.nodeId,
    required this.host,
    required this.port,
    required this.lastSeen,
  });

  final String nodeId;
  final String host;
  final int port;
  final DateTime lastSeen;
}
