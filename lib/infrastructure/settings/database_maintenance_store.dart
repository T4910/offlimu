import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String databaseLastVacuumAtMsPreferenceKey = 'database_last_vacuum_at_ms';

class DatabaseMaintenanceStore {
  const DatabaseMaintenanceStore();

  Future<DateTime?> readLastVacuumAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? value = prefs.getInt(databaseLastVacuumAtMsPreferenceKey);
      if (value == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(value);
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> writeLastVacuumAt(DateTime at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        databaseLastVacuumAtMsPreferenceKey,
        at.millisecondsSinceEpoch,
      );
    } on MissingPluginException {
      // Persistence may be unavailable in some test/runtime contexts.
    }
  }
}
