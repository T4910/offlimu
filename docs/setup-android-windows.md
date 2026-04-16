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
