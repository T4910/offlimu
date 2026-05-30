## OffLiMU Sync Server Todo: Wallet and Token Support

The Flutter client now has a wallet/payment UI. The sync server still needs the actual reconciliation and issuance mechanics that make the UI meaningful.

### 1. Wallet ledger API
- Add a server-side wallet ledger model for internal DTN tokens.
- Store token issuance, spend, confirmation, rejection, and reward events as append-only records.
- Derive balance from events rather than mutating a single balance field.
- Keep client node IDs and wallet identities separate from transport identities.

### 2. Offline spend reconciliation
- Accept uploaded spend events from gateway nodes.
- Verify sender signature, sender identity, timestamp, TTL, and transaction structure.
- Reject malformed, expired, duplicated, or replayed spend events.
- Detect double-spend attempts using server-side ordering and authoritative ledger state.
- Return signed confirmation or rejection events to the client.

### 3. Confirmation / rejection propagation
- Generate signed confirmation bundles for valid spends.
- Generate signed rejection bundles for invalid or conflicting spends.
- Make confirmation and rejection events propagatable through the DTN network like other bundles.
- Preserve the original spend bundle ID so clients can match the reconciliation result.

### 4. Reward issuance
- Issue relay participation rewards based on delivery acknowledgments.
- Issue gateway rewards based on successful upload, validation, and reconciliation runs.
- Sign reward events on the server before they are propagated back through DTN.
- Prevent duplicate reward issuance for the same underlying delivery or sync run.

### 5. Sync endpoints and data exchange
- Add an endpoint for uploading pending spend events.
- Add an endpoint for fetching confirmations, rejections, and reward issuance events since a timestamp.
- Add pagination or cursor support for large reconciliation histories.
- Support idempotent retries using event IDs / bundle IDs.

### 6. Replay protection and auditability
- Track processed event IDs and bundle IDs to prevent duplicate processing.
- Record who uploaded the event, when it was seen, and which server decision was made.
- Expose enough audit information to reconstruct balance changes during debugging.

### 7. Operational safeguards
- Add rate limiting for uploads per node or install.
- Add basic server metrics for accepted spends, rejected spends, issued rewards, and duplicate submissions.
- Keep all token value internal to OffLiMU; no external cash-out or real banking integration.

### 8. Server tests to add
- Unit tests for signature verification, double-spend detection, and event ordering.
- Tests for confirmation and rejection bundle generation.
- Tests for reward issuance idempotency.
- Tests for replay resistance and duplicate upload handling.
- End-to-end sync tests that cover a valid spend, an invalid spend, and a reward issuance path.

