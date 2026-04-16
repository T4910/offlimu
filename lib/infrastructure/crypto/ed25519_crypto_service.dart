import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:offlimu/domain/services/crypto_service.dart';

import '../identity/flutter_secure_storage_node_identity_vault.dart';

class Ed25519CryptoService implements CryptoService {
  Ed25519CryptoService({
    NodeIdentityVault? vault,
    Ed25519? algorithm,
    Random? random,
  }) : _vault = vault ?? FlutterSecureStorageNodeIdentityVault(),
       _algorithm = algorithm ?? Ed25519(),
       _random = random ?? Random.secure();

  static const int _seedLength = 32;

  final NodeIdentityVault _vault;
  final Ed25519 _algorithm;
  final Random _random;

  @override
  Future<String> sign(String payload) async {
    final keyPair = await _loadOrCreateKeyPair();
    final signature = await _algorithm.sign(
      utf8.encode(payload),
      keyPair: keyPair,
    );
    return base64Encode(signature.bytes);
  }

  @override
  Future<bool> verify({
    required String payload,
    required String signature,
    required String publicKey,
  }) async {
    try {
      final publicKeyBytes = base64Decode(publicKey);
      final signatureBytes = base64Decode(signature);
      final valid = await _algorithm.verify(
        utf8.encode(payload),
        signature: Signature(
          signatureBytes,
          publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
        ),
      );
      return valid;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> sha256(String payload) async {
    return crypto.sha256.convert(utf8.encode(payload)).toString();
  }

  Future<SimpleKeyPair> _loadOrCreateKeyPair() async {
    final seed = await _loadOrCreateSeed();
    return _algorithm.newKeyPairFromSeed(seed);
  }

  Future<List<int>> _loadOrCreateSeed() async {
    final existing = await _vault.readSeed();
    if (existing != null) {
      try {
        final decoded = base64Decode(existing);
        if (decoded.length == _seedLength) {
          return decoded;
        }
      } catch (_) {
        // Regenerate below.
      }
    }

    final seed = List<int>.generate(_seedLength, (_) => _random.nextInt(256));
    await _vault.writeSeed(base64Encode(seed));
    return seed;
  }
}
