import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/infrastructure/identity/flutter_secure_storage_node_identity_vault.dart';
import 'package:offlimu/infrastructure/identity/secure_node_identity_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loadOrCreate persists and reuses the same key seed', () async {
    final vault = _InMemoryNodeIdentityVault();
    final store = SecureNodeIdentityStore(vault: vault, random: Random(42));

    final first = await store.loadOrCreate(displayName: 'OffLiMU Node');
    final second = await store.loadOrCreate(displayName: 'OffLiMU Node');

    expect(first.nodeId, startsWith('node-'));
    expect(first.displayName, 'OffLiMU Node');
    expect(first.publicKeyBase64, isNotEmpty);
    expect(first.publicKeyFingerprint, isNotEmpty);
    expect(second.publicKeyBase64, first.publicKeyBase64);
    expect(second.publicKeyFingerprint, first.publicKeyFingerprint);
    expect(second.nodeId, first.nodeId);
    expect(vault.nodeId, first.nodeId);
    expect(vault.seed, isNotNull);
    expect(base64Decode(vault.seed!).length, 32);
  });

  test('rotate keeps the same node id but generates a new public identity', () async {
    final vault = _InMemoryNodeIdentityVault();
    final store = SecureNodeIdentityStore(vault: vault, random: Random(42));

    final first = await store.loadOrCreate(displayName: 'OffLiMU Node');
    final rotated = await store.rotate(displayName: 'OffLiMU Node');

    expect(rotated.nodeId, first.nodeId);
    expect(rotated.publicKeyBase64, isNot(first.publicKeyBase64));
    expect(rotated.publicKeyFingerprint, isNot(first.publicKeyFingerprint));
    expect(vault.seed, isNotNull);
  });

  test('macOS vault uses shared preferences storage', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final previousPlatformOverride = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = previousPlatformOverride;
    });

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final vault = FlutterSecureStorageNodeIdentityVault(
      sharedPreferences: prefs,
    );

    await vault.writeSeed('seed-value');

    expect(await vault.readSeed(), 'seed-value');
  });
}

class _InMemoryNodeIdentityVault implements NodeIdentityVault {
  String? nodeId;
  String? seed;

  @override
  Future<String?> readSeed() async => seed;

  @override
  Future<void> writeSeed(String value) async {
    seed = value;
  }

  @override
  Future<String?> readNodeId() async => nodeId;

  @override
  Future<void> writeNodeId(String value) async {
    nodeId = value;
  }
}
