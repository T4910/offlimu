class PeerContact {
  const PeerContact({
    required this.nodeId,
    required this.host,
    required this.port,
    required this.lastSeen,
    this.seenCount = 1,
  });

  final String nodeId;
  final String host;
  final int port;
  final DateTime lastSeen;
  final int seenCount;
}
