#!/usr/bin/env bash
set -euo pipefail

flutter run \
  --dart-define=OFFLIMU_ENV=demo \
  --dart-define=OFFLIMU_NODE_ID=node-demo-b \
  --dart-define=OFFLIMU_TCP_PORT=47802 \
  --dart-define=OFFLIMU_DISCOVERY_PORT=46671 \
  --dart-define=OFFLIMU_SYNC_MOCK=true
