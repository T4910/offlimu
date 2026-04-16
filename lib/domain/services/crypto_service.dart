abstract interface class CryptoService {
  Future<String> sign(String payload);
  Future<bool> verify({
    required String payload,
    required String signature,
    required String publicKey,
  });
  Future<String> sha256(String payload);
}
