import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String gatewaySyncEnabledPreferenceKey = 'gateway_sync_enabled';

class GatewaySyncPreferenceStore {
  const GatewaySyncPreferenceStore();

  Future<bool?> readEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(gatewaySyncEnabledPreferenceKey)) {
        return null;
      }
      return prefs.getBool(gatewaySyncEnabledPreferenceKey);
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> writeEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(gatewaySyncEnabledPreferenceKey, enabled);
    } on MissingPluginException {
      // Preference persistence can be unavailable in some test/runtime contexts.
    }
  }

  Future<bool> readEnabledOrDefault({bool defaultValue = true}) async {
    final value = await readEnabled();
    return value ?? defaultValue;
  }
}
