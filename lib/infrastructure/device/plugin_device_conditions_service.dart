import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:offlimu/domain/services/device_conditions_service.dart';

class PluginDeviceConditionsService implements DeviceConditionsService {
  PluginDeviceConditionsService({Connectivity? connectivity, Battery? battery})
    : _connectivity = connectivity ?? Connectivity(),
      _battery = battery ?? Battery();

  final Connectivity _connectivity;
  final Battery _battery;

  @override
  Future<DeviceConditionsSnapshot> read() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final connectionType = _mapConnectionType(connectivityResults);

    int? batteryLevelPercent;
    bool isCharging = false;

    try {
      batteryLevelPercent = await _battery.batteryLevel;
    } catch (_) {
      batteryLevelPercent = null;
    }

    try {
      final batteryState = await _battery.batteryState;
      isCharging =
          batteryState == BatteryState.charging ||
          batteryState == BatteryState.full;
    } catch (_) {
      isCharging = false;
    }

    final internetReachable = await _isInternetReachable();

    return DeviceConditionsSnapshot(
      connectionType: connectionType,
      internetReachable: internetReachable,
      batteryLevelPercent: batteryLevelPercent,
      isCharging: isCharging,
    );
  }

  DeviceConnectionType _mapConnectionType(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return DeviceConnectionType.none;
    }
    if (results.contains(ConnectivityResult.wifi)) {
      return DeviceConnectionType.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return DeviceConnectionType.mobile;
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return DeviceConnectionType.ethernet;
    }
    if (results.contains(ConnectivityResult.vpn)) {
      return DeviceConnectionType.vpn;
    }
    return DeviceConnectionType.unknown;
  }

  Future<bool> _isInternetReachable() async {
    try {
      final addresses = await InternetAddress.lookup('one.one.one.one');
      return addresses.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
