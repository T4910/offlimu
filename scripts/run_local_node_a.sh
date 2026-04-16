#!/usr/bin/env bash
set -euo pipefail

flutter run \
  --dart-define=OFFLIMU_ENV=demo \
  --dart-define=OFFLIMU_NODE_ID=node-demo-a \
  --dart-define=OFFLIMU_TCP_PORT=47801 \
  --dart-define=OFFLIMU_DISCOVERY_PORT=46670 \
  --dart-define=OFFLIMU_SYNC_MOCK=true
