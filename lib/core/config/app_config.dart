enum OfflimuEnvironment {
  dev,
  demo,
  prod;

  static OfflimuEnvironment fromWire(String value) {
    return switch (value.toLowerCase()) {
      'demo' => OfflimuEnvironment.demo,
      'prod' => OfflimuEnvironment.prod,
      _ => OfflimuEnvironment.dev,
    };
  }
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.localNodeId,
    required this.transportPort,
    required this.discoveryPort,
    required this.syncMockMode,
    required this.syncBaseUrl,
    required this.syncAllowMeteredNetwork,
    required this.syncMinBatteryPercent,
    required this.syncRequireChargingWhenLowBattery,
    required this.maxBundleHopCount,
    required this.contentStoreMaxBytes,
    required this.maxPendingBundles,
    required this.dbVacuumIntervalMinutes,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      environment: OfflimuEnvironment.fromWire(
        const String.fromEnvironment('OFFLIMU_ENV', defaultValue: 'dev'),
      ),
      localNodeId: const String.fromEnvironment(
        'OFFLIMU_NODE_ID',
        defaultValue: 'node-local-001',
      ),
      transportPort: const int.fromEnvironment(
        'OFFLIMU_TCP_PORT',
        defaultValue: 47800,
      ),
      discoveryPort: const int.fromEnvironment(
        'OFFLIMU_DISCOVERY_PORT',
        defaultValue: 46666,
      ),
      syncMockMode: const bool.fromEnvironment(
        'OFFLIMU_SYNC_MOCK',
        defaultValue: true,
      ),
      syncBaseUrl: const String.fromEnvironment(
        'OFFLIMU_SYNC_BASE_URL',
        defaultValue: 'http://127.0.0.1:8080',
      ),
      syncAllowMeteredNetwork: const bool.fromEnvironment(
        'OFFLIMU_SYNC_ALLOW_METERED',
        defaultValue: true,
      ),
      syncMinBatteryPercent: const int.fromEnvironment(
        'OFFLIMU_SYNC_MIN_BATTERY_PERCENT',
        defaultValue: 20,
      ),
      syncRequireChargingWhenLowBattery: const bool.fromEnvironment(
        'OFFLIMU_SYNC_REQUIRE_CHARGING_LOW_BATTERY',
        defaultValue: true,
      ),
      maxBundleHopCount: const int.fromEnvironment(
        'OFFLIMU_MAX_BUNDLE_HOPS',
        defaultValue: 5,
      ),
      contentStoreMaxBytes: const int.fromEnvironment(
        'OFFLIMU_CONTENT_MAX_BYTES',
        defaultValue: 256 * 1024 * 1024,
      ),
      maxPendingBundles: const int.fromEnvironment(
        'OFFLIMU_MAX_PENDING_BUNDLES',
        defaultValue: 1000,
      ),
      dbVacuumIntervalMinutes: const int.fromEnvironment(
        'OFFLIMU_DB_VACUUM_INTERVAL_MINUTES',
        defaultValue: 24 * 60,
      ),
    );
  }

  final OfflimuEnvironment environment;
  final String localNodeId;
  final int transportPort;
  final int discoveryPort;
  final bool syncMockMode;
  final String syncBaseUrl;
  final bool syncAllowMeteredNetwork;
  final int syncMinBatteryPercent;
  final bool syncRequireChargingWhenLowBattery;
  final int maxBundleHopCount;
  final int contentStoreMaxBytes;
  final int maxPendingBundles;
  final int dbVacuumIntervalMinutes;
}
