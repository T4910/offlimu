# Manual QA Matrix

## Android

- Discovery: two devices discover each other on same hotspot.
- Offline chat: send/receive works with ACK delivery state.
- Restart persistence: pending queue survives restart.
- File transfer: metadata + chunks + progress render correctly.
- Gateway sync: manual sync succeeds when internet is reachable.

## Windows

- Two-instance LAN simulation works locally.
- Socket transport remains stable under repeated sends.
- Drift DB persistence survives app restart.
- Queue and sync status render without errors.

## Test Execution Script (per platform)

1. Start both nodes with unique IDs and ports.
2. Verify peer discovery in Node Status.
3. Send chat and verify acked state.
4. Kill one node, enqueue message, restart, verify delivery.
5. Share file and verify transfer completion.
6. Run Sync Now and verify sync history entry.
7. Record result as pass/fail with notes.
