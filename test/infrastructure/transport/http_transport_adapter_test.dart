import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/services/discovery_adapter.dart';
import 'package:offlimu/infrastructure/transport/http_transport_adapter.dart';

Future<int> _allocatePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

void main() {
  test('HTTP transport sends and receives bundles directly', () async {
    final receiverPort = await _allocatePort();
    final senderPort = await _allocatePort();

    final receiver = HttpTransportAdapter(listenPort: receiverPort);
    final sender = HttpTransportAdapter(listenPort: senderPort);

    final receivedBundle = Completer<Bundle>();
    final sub = receiver.incomingBundles().listen((bundle) {
      if (!receivedBundle.isCompleted) {
        receivedBundle.complete(bundle);
      }
    });

    addTearDown(() async {
      await sub.cancel();
      await sender.stop();
      await receiver.stop();
    });

    await receiver.start();
    await sender.start();

    final bundle = Bundle(
      bundleId: 'http-bundle-1',
      type: Bundle.typeChatMessage,
      sourceNodeId: 'node-a',
      sourcePublicKey: 'public-key-a',
      destinationNodeId: 'node-b',
      payload: 'hello over http',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      ttlSeconds: 3600,
      signature: 'signature-a',
    );

    sender.registerPeer(
      DiscoveredPeer(
        nodeId: 'node-b',
        host: InternetAddress.loopbackIPv4.address,
        port: receiver.boundPort,
        lastSeen: DateTime.now(),
      ),
    );

    expect(await sender.isPeerAlive(peerNodeId: 'node-b'), isTrue);

    await sender.sendBundle(peerNodeId: 'node-b', bundle: bundle);

    final inbound = await receivedBundle.future.timeout(
      const Duration(seconds: 5),
    );

    expect(inbound.bundleId, bundle.bundleId);
    expect(inbound.type, bundle.type);
    expect(inbound.sourceNodeId, bundle.sourceNodeId);
    expect(inbound.sourcePublicKey, bundle.sourcePublicKey);
    expect(inbound.destinationNodeId, bundle.destinationNodeId);
    expect(inbound.payload, bundle.payload);
    expect(inbound.signature, bundle.signature);
    expect(inbound.hopCount, bundle.hopCount);
  });
}
