import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:offlimu/domain/services/discovery_adapter.dart';

class LanBroadcastDiscoveryAdapter implements DiscoveryAdapter {
  LanBroadcastDiscoveryAdapter({
    required String localNodeId,
    required int transportPort,
    int discoveryPort = 46666,
  })  : _localNodeId = localNodeId,
        _transportPort = transportPort,
        _discoveryPort = discoveryPort;

  final String _localNodeId;
  final int _transportPort;
  final int _discoveryPort;

  final StreamController<DiscoveredPeer> _peerController =
      StreamController<DiscoveredPeer>.broadcast();
  final Map<String, DiscoveredPeer> _knownPeers = <String, DiscoveredPeer>{};

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _socketSubscription;
  Timer? _announceTimer;
  bool _started = false;

  @override
  Stream<DiscoveredPeer> discover() => _peerController.stream;

  @override
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _discoveryPort,
      reuseAddress: true,
      reusePort: true,
    );
    socket.broadcastEnabled = true;
    _socket = socket;

    _socketSubscription = socket.listen((RawSocketEvent event) {
      if (event != RawSocketEvent.read) {
        return;
      }

      Datagram? datagram = socket.receive();
      while (datagram != null) {
        _handleDatagram(datagram);
        datagram = socket.receive();
      }
    });

    _announcePresence();
    _announceTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _announcePresence(),
    );
  }

  @override
  Future<void> stop() async {
    _started = false;
    _announceTimer?.cancel();
    _announceTimer = null;

    await _socketSubscription?.cancel();
    _socketSubscription = null;

    _socket?.close();
    _socket = null;

    _knownPeers.clear();
  }

  void _announcePresence() {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    final String payload = jsonEncode(<String, Object>{
      'kind': 'offlimu_presence',
      'nodeId': _localNodeId,
      'tcpPort': _transportPort,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    socket.send(
      utf8.encode(payload),
      InternetAddress('255.255.255.255'),
      _discoveryPort,
    );
  }

  void _handleDatagram(Datagram datagram) {
    final String decoded = utf8.decode(datagram.data, allowMalformed: true);
    Map<String, dynamic> map;
    try {
      final Object? parsed = jsonDecode(decoded);
      if (parsed is! Map<String, dynamic>) {
        return;
      }
      map = parsed;
    } catch (_) {
      return;
    }

    if (map['kind'] != 'offlimu_presence') {
      return;
    }

    final String? nodeId = map['nodeId'] as String?;
    final int? tcpPort = map['tcpPort'] as int?;
    if (nodeId == null || nodeId == _localNodeId || tcpPort == null) {
      return;
    }

    final DiscoveredPeer peer = DiscoveredPeer(
      nodeId: nodeId,
      host: datagram.address.address,
      port: tcpPort,
      lastSeen: DateTime.now(),
    );

    final DiscoveredPeer? previous = _knownPeers[nodeId];
    _knownPeers[nodeId] = peer;

    if (previous == null || previous.host != peer.host || previous.port != peer.port) {
      _peerController.add(peer);
      return;
    }

    if (DateTime.now().difference(previous.lastSeen).inSeconds >= 10) {
      _peerController.add(peer);
    }
  }
}
