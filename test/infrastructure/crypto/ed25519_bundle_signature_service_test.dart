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
