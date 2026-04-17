# Android and Windows Setup

## Prerequisites

- Flutter SDK installed and on PATH.
- `flutter doctor` reports no blocking issues.
- Repository dependencies installed via `flutter pub get`.

## Android Setup

1. Enable developer options and USB debugging on device.
2. Connect device and verify with:

   ```bash
   flutter devices
   ```

3. Run node A profile:

   ```bash
   flutter run -d <android-device-id> \
     --dart-define=OFFLIMU_ENV=demo \
     --dart-define=OFFLIMU_NODE_ID=node-android-a \
     --dart-define=OFFLIMU_TCP_PORT=47811 \
     --dart-define=OFFLIMU_DISCOVERY_PORT=46680
   ```

4. Run node B profile on second Android device (different IDs/ports).

## Windows Setup

1. Ensure Windows desktop support is enabled:

   ```bash
   flutter config --enable-windows-desktop
   ```

2. Verify toolchain:

   ```bash
   flutter doctor -v
   ```

3. Run two local instances with distinct config values in separate terminals:

   Terminal A:

   ```bash
   flutter run -d windows \
     --dart-define=OFFLIMU_ENV=demo \
     --dart-define=OFFLIMU_NODE_ID=node-win-a \
     --dart-define=OFFLIMU_TCP_PORT=47821 \
     --dart-define=OFFLIMU_DISCOVERY_PORT=46690
   ```

   Terminal B:

   ```bash
   flutter run -d windows \
     --dart-define=OFFLIMU_ENV=demo \
     --dart-define=OFFLIMU_NODE_ID=node-win-b \
     --dart-define=OFFLIMU_TCP_PORT=47822 \
     --dart-define=OFFLIMU_DISCOVERY_PORT=46691
   ```

## Platform Notes

- Android now ships the required LAN discovery and background-work permissions in the app manifest: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`, `WAKE_LOCK`, and `RECEIVE_BOOT_COMPLETED`.
- For Android device demos, keep both devices on the same hotspot or LAN and expect battery optimizations to affect discovery reliability on some devices.
- iOS and macOS now include the local-network privacy declaration and Bonjour service entry for `_offlimu._tcp`.
- macOS builds require CocoaPods to be installed locally before `flutter build macos` or `flutter run -d macos` will work with plugins.
- On Windows, allow the first Defender Firewall prompt for the app so local TCP discovery and transport can bind and connect normally.
