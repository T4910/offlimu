import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class NodeIdentityVault {
  Future<String?> readSeed();
  Future<void> writeSeed(String value);
}

class FlutterSecureStorageNodeIdentityVault implements NodeIdentityVault {
  FlutterSecureStorageNodeIdentityVault({
    FlutterSecureStorage? storage,
    SharedPreferences? sharedPreferences,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _sharedPreferences = sharedPreferences;

  static const String _seedKey = 'offlimu.node.identity.seed';

  final FlutterSecureStorage _storage;
  final SharedPreferences? _sharedPreferences;
  SharedPreferences? _cachedSharedPreferences;
  bool get _usesSharedPreferencesOnly =>
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Future<String?> readSeed() async {
    if (_usesSharedPreferencesOnly) {
      return _readFromSharedPreferences();
    }

    return _storage.read(key: _seedKey);
  }

  @override
  Future<void> writeSeed(String value) async {
    if (_usesSharedPreferencesOnly) {
      await _writeToSharedPreferences(value);
      return;
    }

    await _storage.write(key: _seedKey, value: value);
  }

  Future<String?> _readFromSharedPreferences() async {
    final prefs = await _getSharedPreferences();
    return prefs.getString(_seedKey);
  }

  Future<void> _writeToSharedPreferences(String value) async {
    final prefs = await _getSharedPreferences();
    await prefs.setString(_seedKey, value);
  }

  Future<SharedPreferences> _getSharedPreferences() async {
    return _cachedSharedPreferences ??=
        _sharedPreferences ?? await SharedPreferences.getInstance();
  }
}
