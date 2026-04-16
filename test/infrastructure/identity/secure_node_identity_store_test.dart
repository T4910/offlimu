import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/infrastructure/identity/flutter_secure_storage_node_identity_vault.dart';
import 'package:offlimu/infrastructure/identity/secure_node_identity_store.dart';

void main() {
  test('loadOrCreate persists and reuses the same key seed', () async {
    final vault = _InMemoryNodeIdentityVault();
    final store = SecureNodeIdentityStore(vault: vault, random: Random(42));

    final first = await store.loadOrCreate(
      nodeId: 'node-a',
      displayName: 'OffLiMU Node',
    );
    final second = await store.loadOrCreate(
      nodeId: 'node-a',
      displayName: 'OffLiMU Node',
    );

    expect(first.nodeId, 'node-a');
    expect(first.displayName, 'OffLiMU Node');
    expect(first.publicKeyBase64, isNotEmpty);
    expect(first.publicKeyFingerprint, isNotEmpty);
    expect(second.publicKeyBase64, first.publicKeyBase64);
    expect(second.publicKeyFingerprint, first.publicKeyFingerprint);
    expect(vault.seed, isNotNull);
    expect(base64Decode(vault.seed!).length, 32);
  });

  test('rotate generates a new public identity', () async {
    final vault = _InMemoryNodeIdentityVault();
    final store = SecureNodeIdentityStore(vault: vault, random: Random(42));

    final first = await store.loadOrCreate(
      nodeId: 'node-a',
      displayName: 'OffLiMU Node',
    );
    final rotated = await store.rotate(
      nodeId: 'node-a',
      displayName: 'OffLiMU Node',
    );

    expect(rotated.publicKeyBase64, isNot(first.publicKeyBase64));
    expect(rotated.publicKeyFingerprint, isNot(first.publicKeyFingerprint));
    expect(vault.seed, isNotNull);
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
