import 'package:offlimu/core/debug/runtime_log_store.dart';
import 'package:offlimu/core/error/app_error_log_store.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/settings/database_maintenance_store.dart';
import 'package:offlimu/infrastructure/settings/gateway_sync_preference_store.dart';
import 'package:offlimu/node_runtime/node_runtime.dart';

class AppDataResetService {
  AppDataResetService({
    required NodeRuntime runtime,
    required AppDatabase database,
    required ContentStore contentStore,
    required RuntimeLogStore runtimeLogStore,
    required AppErrorLogStore errorLogStore,
    required GatewaySyncPreferenceStore gatewaySyncPreferenceStore,
    required DatabaseMaintenanceStore databaseMaintenanceStore,
  }) : _runtime = runtime,
       _database = database,
       _contentStore = contentStore,
       _runtimeLogStore = runtimeLogStore,
       _errorLogStore = errorLogStore,
       _gatewaySyncPreferenceStore = gatewaySyncPreferenceStore,
       _databaseMaintenanceStore = databaseMaintenanceStore;

  final NodeRuntime _runtime;
  final AppDatabase _database;
  final ContentStore _contentStore;
  final RuntimeLogStore _runtimeLogStore;
  final AppErrorLogStore _errorLogStore;
  final GatewaySyncPreferenceStore _gatewaySyncPreferenceStore;
  final DatabaseMaintenanceStore _databaseMaintenanceStore;

  Future<void> resetAll() async {
    await _runtime.stop();
    await _database.clearAllUserData();
    await _contentStore.clear();
    _runtimeLogStore.clear();
    await _errorLogStore.clear();
    await _gatewaySyncPreferenceStore.clear();
    await _databaseMaintenanceStore.clear();
  }
}