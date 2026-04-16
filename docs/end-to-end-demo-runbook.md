# End-to-End Demo Runbook

## Goal

Demonstrate discovery, offline delivery, ACK transition, queue persistence, and gateway sync in one timed sequence.

## Sequence (8-10 Minutes)

1. Start Node A and Node B using launch profiles.
2. Confirm both peers appear in Node Status peer history.
3. Send chat from A to B and show delivery state transition.
4. Share a small file from A and show transfer progress on B.
5. Stop one node briefly, queue a message, restart, and verify delivery retry.
6. Trigger Sync Now with gateway enabled and show sync history entry.
7. Open diagnostics panels and confirm runtime/queue/error visibility.

## Failure Handling

- If discovery is delayed, verify both instances are on same network and ports are unique.
- If delivery stalls, open queue screen and verify pending bundle count.
- If sync fails, check internet reachability and gateway toggle state.

## Evidence to Capture

- Peer history row for both nodes.
- Chat message with acked state.
- File transfer progress and completion.
- Sync history row with timestamp and counts.
- Diagnostics cards (transport status and error events).
