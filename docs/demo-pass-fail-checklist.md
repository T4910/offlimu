# OffLiMU Demo Pass/Fail Checklist

## Preconditions

- [ ] Two devices or two desktop instances are prepared.
- [ ] Both nodes have unique node IDs and non-overlapping ports.
- [ ] Gateway URL and mock mode are set as intended for the demo.

## Core Flow

- [ ] Node discovery: each node appears in peer history.
- [ ] Offline message delivery: chat message sent from node A is visible on node B.
- [ ] Queue persistence: pending bundle remains after restart and is retried.
- [ ] ACK transition: sender message state moves to acked.
- [ ] Gateway sync: manual sync succeeds when internet is reachable.

## File Sharing Flow

- [ ] File metadata is emitted and received.
- [ ] File chunks transfer and resumable behavior is observed.
- [ ] Transfer progress is visible in UI.

## Diagnostics Evidence

- [ ] Runtime health and peer counters are visible.
- [ ] Queue/transport status is visible.
- [ ] Recent error events panel is visible and empty or understood.
- [ ] Sync history records at least one run.
