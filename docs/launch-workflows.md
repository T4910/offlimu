# Launch Workflows

## Local Two-Node (Desktop)

Use two terminals from repository root.

Terminal A:

flutter run \
  --dart-define=OFFLIMU_ENV=demo \
  --dart-define=OFFLIMU_NODE_ID=node-demo-a \
  --dart-define=OFFLIMU_TCP_PORT=47801 \
  --dart-define=OFFLIMU_DISCOVERY_PORT=46670 \
  --dart-define=OFFLIMU_SYNC_MOCK=false \
  --dart-define=OFFLIMU_SYNC_BASE_URL=http://localhost:7774

Terminal B:

flutter run \
  --dart-define=OFFLIMU_ENV=demo \
  --dart-define=OFFLIMU_NODE_ID=node-demo-b \
  --dart-define=OFFLIMU_TCP_PORT=47802 \
  --dart-define=OFFLIMU_DISCOVERY_PORT=46671 \
  --dart-define=OFFLIMU_SYNC_MOCK=false \
  --dart-define=OFFLIMU_SYNC_BASE_URL=http://localhost:7774

## Scripted One-Command Profiles

- scripts/run_local_node_a.sh
- scripts/run_local_node_b.sh

Each script sets explicit runtime identifiers and starts a node instance.

Start the TypeScript sync server first:

```sh
cd server
pnpm install
pnpm dev
```

Mock sync remains available for isolated demos by passing
`--dart-define=OFFLIMU_SYNC_MOCK=true`.

## Android Physical Device

flutter run -d <device-id> \
  --dart-define=OFFLIMU_ENV=demo \
  --dart-define=OFFLIMU_NODE_ID=node-android-a \
  --dart-define=OFFLIMU_TCP_PORT=47811 \
  --dart-define=OFFLIMU_DISCOVERY_PORT=46680

## Windows

flutter run -d windows \
  --dart-define=OFFLIMU_ENV=demo \
  --dart-define=OFFLIMU_NODE_ID=node-win-a \
  --dart-define=OFFLIMU_TCP_PORT=47821 \
  --dart-define=OFFLIMU_DISCOVERY_PORT=46690
