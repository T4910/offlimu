import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class NodeIdentityVault {
  Future<String?> readSeed();
  Future<void> writeSeed(String value);
}

class FlutterSecureStorageNodeIdentityVault implements NodeIdentityVault {
  FlutterSecureStorageNodeIdentityVault({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _seedKey = 'offlimu.node.identity.seed';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readSeed() {
    return _storage.read(key: _seedKey);
  }

  @override
  Future<void> writeSeed(String value) {
    return _storage.write(key: _seedKey, value: value);
  }
}
