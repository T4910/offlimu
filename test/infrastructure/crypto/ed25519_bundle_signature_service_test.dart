import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/infrastructure/crypto/ed25519_bundle_signature_service.dart';
import 'package:offlimu/infrastructure/identity/flutter_secure_storage_node_identity_vault.dart';
import 'package:offlimu/infrastructure/identity/secure_node_identity_store.dart';
import 'package:offlimu/infrastructure/crypto/ed25519_crypto_service.dart';

void main() {
  test('signs and verifies bundles with persisted identity', () async {
    final vault = _InMemoryNodeIdentityVault();
    final identityStore = SecureNodeIdentityStore(
      vault: vault,
      random: Random(7),
    );
    final cryptoService = Ed25519CryptoService(vault: vault, random: Random(7));
    final signatureService = Ed25519BundleSignatureService(
      cryptoService: cryptoService,
      nodeIdentityStore: identityStore,
      displayName: 'OffLiMU Node',
    );

    final bundle = Bundle(
      bundleId: 'bundle-1',
      type: Bundle.typeChatMessage,
      sourceNodeId: 'node-a',
      destinationNodeId: 'node-b',
      payload: 'hello',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      ttlSeconds: 3600,
    );

    final signed = await signatureService.sign(
      bundle: bundle,
      nodeId: 'node-a',
    );

    expect(signed.signature, isNotNull);
    expect(signed.sourcePublicKey, isNotNull);
    expect(await signatureService.verify(signed), isTrue);

    final tampered = signed.copyWith(payload: 'goodbye');
    expect(await signatureService.verify(tampered), isFalse);
    expect(base64Decode(vault.seed!).length, 32);
  });

  test('verification survives hop count changes during forwarding', () async {
    final vault = _InMemoryNodeIdentityVault();
    final identityStore = SecureNodeIdentityStore(
      vault: vault,
      random: Random(7),
    );
    final cryptoService = Ed25519CryptoService(vault: vault, random: Random(7));
    final signatureService = Ed25519BundleSignatureService(
      cryptoService: cryptoService,
      nodeIdentityStore: identityStore,
      displayName: 'OffLiMU Node',
    );

    final bundle = Bundle(
      bundleId: 'bundle-2',
      type: Bundle.typeChatMessage,
      sourceNodeId: 'node-a',
      destinationNodeId: 'node-b',
      payload: 'hello again',
      createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
      ttlSeconds: 3600,
    );

    final signed = await signatureService.sign(
      bundle: bundle,
      nodeId: 'node-a',
    );

    final forwarded = signed.copyWith(hopCount: signed.hopCount + 1);

    expect(forwarded.hopCount, signed.hopCount + 1);
    expect(await signatureService.verify(forwarded), isTrue);
  });

  test('verification accepts legacy hop-count-inclusive signatures', () async {
    final vault = _InMemoryNodeIdentityVault();
    final identityStore = SecureNodeIdentityStore(
      vault: vault,
      random: Random(7),
    );
    final cryptoService = Ed25519CryptoService(vault: vault, random: Random(7));
    final signatureService = Ed25519BundleSignatureService(
      cryptoService: cryptoService,
      nodeIdentityStore: identityStore,
      displayName: 'OffLiMU Node',
    );

    final bundle = Bundle(
      bundleId: 'bundle-3',
      type: Bundle.typeChatMessage,
      sourceNodeId: 'node-a',
      destinationNodeId: 'node-b',
      payload: 'legacy hello',
      createdAt: DateTime.fromMillisecondsSinceEpoch(3000),
      ttlSeconds: 3600,
      hopCount: 2,
    );

    final identity = await identityStore.loadOrCreate(
      nodeId: 'node-a',
      displayName: 'OffLiMU Node',
    );
    final legacyPayload = jsonEncode(<String, Object?>{
      'bundleId': bundle.bundleId,
      'type': bundle.type,
      'sourceNodeId': bundle.sourceNodeId,
      'sourcePublicKey': identity.publicKeyBase64,
      'destinationNodeId': bundle.destinationNodeId,
      'destinationScope': bundle.destinationScope.name,
      'priority': bundle.priority.name,
      'ackForBundleId': bundle.ackForBundleId,
      'payload': bundle.payload,
      'payloadReference': bundle.payloadReference,
      'appId': bundle.appId,
      'createdAtMs': bundle.createdAt.millisecondsSinceEpoch,
      'expiresAtMs': bundle.expiresAtOverride?.millisecondsSinceEpoch,
      'ttlSeconds': bundle.ttlSeconds,
      'hopCount': bundle.hopCount,
    });
    final legacySignature = await cryptoService.sign(legacyPayload);
    final legacySigned = bundle.copyWith(
      sourcePublicKey: identity.publicKeyBase64,
      signature: legacySignature,
    );

    expect(await signatureService.verify(legacySigned), isTrue);
  });
}

class _InMemoryNodeIdentityVault implements NodeIdentityVault {
  String? seed;

  @override
  Future<String?> readSeed() async => seed;

  @override
  Future<void> writeSeed(String value) async {
    seed = value;
  }
}
