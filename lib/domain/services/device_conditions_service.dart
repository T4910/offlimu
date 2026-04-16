enum DeviceConnectionType { wifi, mobile, ethernet, vpn, unknown, none }

class DeviceConditionsSnapshot {
  const DeviceConditionsSnapshot({
    required this.connectionType,
    required this.internetReachable,
    this.batteryLevelPercent,
    required this.isCharging,
  });

  final DeviceConnectionType connectionType;
  final bool internetReachable;
  final int? batteryLevelPercent;
  final bool isCharging;

  bool get hasUnmeteredConnection {
    return connectionType == DeviceConnectionType.wifi ||
        connectionType == DeviceConnectionType.ethernet;
  }
}

abstract interface class DeviceConditionsService {
  Future<DeviceConditionsSnapshot> read();
}
