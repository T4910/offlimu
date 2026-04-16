# Reproducible Build Commands

## Android APK (demo profile)

```bash
flutter build apk --release \
  --dart-define=OFFLIMU_ENV=demo \
  --dart-define=OFFLIMU_NODE_ID=node-release-a \
  --dart-define=OFFLIMU_TCP_PORT=47831 \
  --dart-define=OFFLIMU_DISCOVERY_PORT=46700
```

## Android App Bundle

```bash
flutter build appbundle --release \
  --dart-define=OFFLIMU_ENV=demo
```

## Windows Release Build

```bash
flutter build windows --release \
  --dart-define=OFFLIMU_ENV=demo \
  --dart-define=OFFLIMU_NODE_ID=node-win-release \
  --dart-define=OFFLIMU_TCP_PORT=47841 \
  --dart-define=OFFLIMU_DISCOVERY_PORT=46710
```

## Quality Gate Before Build

```bash
flutter pub get
bash scripts/verify_codegen.sh
flutter analyze
flutter test
```
