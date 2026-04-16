import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nsd/nsd.dart' as nsd;
import 'package:offlimu/domain/services/discovery_adapter.dart';

class NsdDiscoveryAdapter implements DiscoveryAdapter {
  NsdDiscoveryAdapter({
    required String localNodeId,
    required int transportPort,
    required DiscoveryAdapter fallback,
    String serviceType = '_offlimu._tcp',
    String serviceNamePrefix = 'offlimu',
  })  : _localNodeId = localNodeId,
        _transportPort = transportPort,
        _fallback = fallback,
        _serviceType = serviceType,
        _serviceName = '$serviceNamePrefix-$localNodeId';

  final String _localNodeId;
  final int _transportPort;
  final DiscoveryAdapter _fallback;
  final String _serviceType;
  final String _serviceName;

  final StreamController<DiscoveredPeer> _peerController =
      StreamController<DiscoveredPeer>.broadcast();
  final Map<String, DiscoveredPeer> _knownPeers = <String, DiscoveredPeer>{};

  nsd.Discovery? _discovery;
  nsd.Registration? _registration;
  nsd.ServiceListener? _listener;

  StreamSubscription<DiscoveredPeer>? _fallbackSubscription;
  bool _started = false;
  bool _usingFallback = false;

  @override
  Stream<DiscoveredPeer> discover() => _peerController.stream;

  @override
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    try {
      await _startNsd();
    } catch (_) {
      await _startFallback();
    }
  }

  @override
  Future<void> stop() async {
    _started = false;

    if (_usingFallback) {
      await _fallbackSubscription?.cancel();
      _fallbackSubscription = null;
      await _fallback.stop();
      _usingFallback = false;
    }

    final discovery = _discovery;
    final listener = _listener;
    if (discovery != null && listener != null) {
      discovery.removeServiceListener(listener);
    }

    _listener = null;

    if (discovery != null) {
      await nsd.stopDiscovery(discovery);
    }
    _discovery = null;

    final registration = _registration;
    if (registration != null) {
      await nsd.unregister(registration);
    }
    _registration = null;

    _knownPeers.clear();
  }

  Future<void> _startNsd() async {
    final service = nsd.Service(
      name: _serviceName,
      type: _serviceType,
      port: _transportPort,
      txt: <String, Uint8List?>{
        'nodeId': Uint8List.fromList(utf8.encode(_localNodeId)),
      },
    );

    _registration = await nsd.register(service);
    _discovery = await nsd.startDiscovery(_serviceType, autoResolve: true);

    _listener = (nsd.Service service, nsd.ServiceStatus status) async {
      final String nodeId = _extractNodeId(service);
      if (nodeId.isEmpty || nodeId == _localNodeId) {
        return;
      }

      if (status == nsd.ServiceStatus.lost) {
        _knownPeers.remove(nodeId);
        return;
      }

      final String? host = _extractHost(service);
      final int? port = service.port;
      if (host == null || port == null) {
        return;
      }

      final DiscoveredPeer peer = DiscoveredPeer(
        nodeId: nodeId,
        host: host,
        port: port,
        lastSeen: DateTime.now(),
      );

      final previous = _knownPeers[nodeId];
      _knownPeers[nodeId] = peer;

      if (previous == null || previous.host != peer.host || previous.port != peer.port) {
        _peerController.add(peer);
      }
    };

    _discovery?.addServiceListener(_listener!);
  }

  Future<void> _startFallback() async {
    _usingFallback = true;
    await _fallback.start();
    _fallbackSubscription = _fallback.discover().listen(_peerController.add);
  }

  String _extractNodeId(nsd.Service service) {
    final txt = service.txt;
    if (txt != null) {
      final Uint8List? rawNodeId = txt['nodeId'];
      if (rawNodeId != null) {
        final decoded = utf8.decode(rawNodeId, allowMalformed: true).trim();
        if (decoded.isNotEmpty) {
          return decoded;
        }
      }
    }

    final String? serviceName = service.name;
    if (serviceName == null || serviceName.isEmpty) {
      return '';
    }

    final marker = serviceName.indexOf('-');
    if (marker > -1 && marker < serviceName.length - 1) {
      return serviceName.substring(marker + 1);
    }

    return serviceName;
  }

  String? _extractHost(nsd.Service service) {
    final addresses = service.addresses;
    if (addresses != null && addresses.isNotEmpty) {
      return addresses.first.address;
    }

    final host = service.host;
    if (host == null || host.isEmpty) {
      return null;
    }
    return host;
  }
}
