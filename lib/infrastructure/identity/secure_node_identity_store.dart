import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';
import 'package:offlimu/domain/entities/node_public_identity.dart';
import 'package:offlimu/domain/services/node_identity_store.dart';

import 'flutter_secure_storage_node_identity_vault.dart';

class SecureNodeIdentityStore implements NodeIdentityStore {
  SecureNodeIdentityStore({
    NodeIdentityVault? vault,
    Ed25519? algorithm,
    Random? random,
  }) : _vault = vault ?? FlutterSecureStorageNodeIdentityVault(),
       _algorithm = algorithm ?? Ed25519(),
       _random = random ?? Random.secure();

  final NodeIdentityVault _vault;
  final Ed25519 _algorithm;
  final Random _random;

  @override
  Future<NodePublicIdentity> loadOrCreate({
    required String nodeId,
    required String displayName,
  }) async {
    return _loadIdentity(nodeId: nodeId, displayName: displayName);
  }

  @override
  Future<NodePublicIdentity> rotate({
    required String nodeId,
    required String displayName,
  }) async {
    final seed = _generateSeed();
    await _vault.writeSeed(base64Encode(seed));
    return _loadIdentity(nodeId: nodeId, displayName: displayName, seed: seed);
  }

  Future<NodePublicIdentity> _loadIdentity({
    required String nodeId,
    required String displayName,
    List<int>? seed,
  }) async {
    final effectiveSeed = seed ?? await _loadOrCreateSeed();
    final keyPair = await _algorithm.newKeyPairFromSeed(effectiveSeed);
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;
    return NodePublicIdentity(
      nodeId: nodeId,
      displayName: displayName,
      publicKeyBase64: base64Encode(publicKeyBytes),
      publicKeyFingerprint: _fingerprint(publicKeyBytes),
    );
  }

  Future<List<int>> _loadOrCreateSeed() async {
    final existing = await _vault.readSeed();
    if (existing != null) {
      try {
        final decoded = base64Decode(existing);
        if (decoded.length == 32) {
          return decoded;
        }
      } catch (_) {
        // Regenerate below.
      }
    }

    final seed = _generateSeed();
    await _vault.writeSeed(base64Encode(seed));
    return seed;
  }

  List<int> _generateSeed() {
    return List<int>.generate(32, (_) => _random.nextInt(256));
  }

  String _fingerprint(List<int> bytes) {
    return sha256
        .convert(bytes)
        .bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
