# OffLiMU Master TODO (Complete Build Blueprint)

This is the single source of truth for what remains before OffLiMU is considered complete for final-year delivery.

## Legend

- [x] done
- [ ] not started
- [~] in progress
- Priority tags:
	- `[MVP]` must ship this semester
	- `[DEMO]` needed for grading demo reliability
	- `[HARDEN]` quality/stability/security
	- `[POST-MVP]` nice to have after core demo is stable

---

## 0) Scope Lock and Governance

### 0.1 Product scope
- [ ] [MVP] Freeze the final feature scope with supervisor sign-off.
- [ ] [MVP] Convert PDF/chat requirements into a formal specification doc.
- [ ] [MVP] Define in-scope vs out-of-scope explicitly.
- [ ] [MVP] Define what "done" means for semester demo.

### 0.2 Success criteria and KPIs
- [ ] [MVP] Define measurable demo success criteria:
	- [ ] two nodes discover each other on same LAN/hotspot
	- [ ] offline message is delivered between nodes
	- [ ] bundles survive app restart
	- [ ] ACK transitions clear pending queue
	- [ ] gateway sync executes when internet appears
- [x] [DEMO] Create a pass/fail checklist for rehearsal.

### 0.3 Delivery management
- [ ] [MVP] Create milestone dates for each phase.
- [ ] [MVP] Add risk register with mitigations.
- [ ] [MVP] Define rollback plan for risky features.

---

## 1) Architecture and Project Foundation

### 1.1 Layered architecture
- [x] [MVP] Scaffold layered folders (`app/core/domain/infrastructure/node_runtime/features`).
- [x] [MVP] Enforce architecture boundaries in docs (who can import what).
- [x] [HARDEN] Add lint/import rules to reduce cross-layer leaks.

### 1.2 Dependency injection and app bootstrap
- [x] [MVP] Add app shell and Riverpod bootstrap.
- [x] [MVP] Add routing shell (`go_router`).
- [x] [MVP] Add app-wide error boundary strategy.
- [x] [HARDEN] Add global uncaught error logging hook.

### 1.3 Configuration management
- [x] [MVP] Create environment config model (dev/demo/prod).
- [x] [MVP] Support runtime identifiers (`nodeId`, ports, flags).
- [x] [DEMO] Provide one-command launch configs for multi-instance local tests.

---

## 2) Domain Model and Contracts

### 2.1 Entities/value objects
- [x] [MVP] Add basic `Bundle` entity.
- [x] [MVP] Add `NodeIdentity` entity.
- [x] [MVP] Extend `Bundle` to full DTN metadata:
	- [x] destination node or broadcast scope
	- [x] priority
	- [x] hop count
	- [x] expiresAt / TTL policy
	- [x] payload reference and/or inline payload
	- [x] signature
	- [x] appId

### 2.2 Service/repository contracts
- [x] [MVP] Define `DiscoveryAdapter` contract.
- [x] [MVP] Define `TransportAdapter` contract.
- [x] [MVP] Define `BundleRepository` contract.
- [x] [MVP] Define `SyncApi` contract.
- [x] [MVP] Define `CryptoService` contract.
- [x] [MVP] Add `PeerRepository` contract.
- [x] [MVP] Add `ContentStore` contract.
- [x] [MVP] Add `BackgroundScheduler` contract.

---

## 3) Persistence Layer (Drift/SQLite)

### 3.1 Database core
- [x] [MVP] Add Drift DB setup.
- [x] [MVP] Add `bundle_records` table.
- [x] [MVP] Implement Drift bundle repository.
- [x] [MVP] Add schema migration policy and migration tests.

### 3.2 Additional tables
- [x] [MVP] Add `peer_contacts` table.
- [x] [MVP] Add `ack_events` table.
- [x] [MVP] Add `sync_jobs` table.
- [x] [MVP] Add `messages` table (chat payload projection).
- [x] [MVP] Add `content_metadata` table (file hashes/chunks).

### 3.3 Data lifecycle and cleanup
- [x] [MVP] Add TTL expiry cleanup for bundles.
- [x] [HARDEN] Add queue size limits and pruning strategy.
- [x] [HARDEN] Add periodic DB vacuum/health checks if needed.

---

## 4) Discovery and Transport Baseline

### 4.1 Discovery
- [x] [MVP] Implement LAN UDP broadcast discovery adapter.
- [x] [MVP] Implement mDNS/NSD discovery adapter (target baseline from spec).
- [x] [HARDEN] Add peer expiry and stale-peer removal.
- [x] [HARDEN] Add duplicate peer suppression and update policy.

### 4.2 Transport
- [x] [MVP] Implement TCP socket send/receive transport.
- [x] [MVP] Add message framing robustness (length-prefix or protocol framing).
- [x] [HARDEN] Add socket retry/backoff.
- [x] [HARDEN] Add heartbeat or liveness checks.

### 4.3 Runtime wiring
- [x] [MVP] Wire discovery + transport into `NodeRuntime`.
- [x] [MVP] Add start/stop controls in UI.
- [x] [MVP] Add runtime status transitions beyond basic states.
- [x] [HARDEN] Add runtime telemetry counters.

---

## 5) Bundle Pipeline and ACK Semantics

### 5.1 Bundle lifecycle
- [x] [MVP] Persist pending bundles.
- [x] [MVP] Auto-forward pending local bundles to discovered peers.
- [x] [MVP] Add inbound routing by bundle type.
- [x] [MVP] Add retry policy for failed sends.

### 5.2 ACK model
- [x] [MVP] Define explicit ACK bundle schema.
- [x] [MVP] Generate ACK bundle on receive.
- [x] [MVP] Process ACK bundle and transition sender state.
- [x] [MVP] Store ACK history for auditability.
- [x] [HARDEN] Handle duplicate ACKs idempotently.

### 5.3 Routing and forwarding
- [x] [MVP] Add hopCount handling.
- [x] [MVP] Add TTL handling in routing decisions.
- [x] [MVP] Add simple forwarding strategy (direct + opportunistic relay).
- [x] [POST-MVP] Add smarter routing heuristics.

---

## 6) Feature: Chat (First Vertical Slice)

### 6.1 Domain/use cases
- [x] [MVP] Create `SendChatMessageUseCase`.
- [x] [MVP] Create `ReceiveChatMessageUseCase`.
- [x] [MVP] Create message-to-bundle and bundle-to-message mappers.

### 6.2 UI
- [x] [MVP] Build chat list screen.
- [x] [MVP] Build conversation detail screen.
- [x] [MVP] Build message composer.
- [x] [MVP] Show delivery state badges (`pending/sent/acked/failed`).

### 6.3 Persistence integration
- [x] [MVP] Persist chat projections for quick rendering.
- [x] [MVP] Link message rows to bundle IDs.
- [x] [HARDEN] Add pagination for long histories.

---

## 7) Feature: File/Media Sharing

### 7.1 Content-addressed storage
- [x] [MVP] Implement local content store directory layout.
- [x] [MVP] Compute SHA-256 for files/chunks.
- [x] [MVP] Store metadata records in DB.

### 7.2 Transfer flow
- [x] [MVP] Create file-share metadata bundle type.
- [x] [MVP] Add chunk transfer protocol over TCP.
- [x] [MVP] Add resumable transfer support.
- [x] [DEMO] Show transfer progress in UI.

### 7.3 UX and safety
- [x] [MVP] Build file picker UI.
- [x] [MVP] Add MIME/type and size validation.
- [x] [HARDEN] Add disk quota safeguards.

---

## 8) Gateway Sync (Internet Reconciliation)

### 8.1 Sync fundamentals
- [x] [MVP] Define sync API contract and request/response schema.
- [x] [MVP] Implement `DioSyncApi` adapter.
- [x] [MVP] Implement `SyncEngine` queue processor.

### 8.2 Gateway eligibility
- [x] [MVP] Detect internet reachability (not just network connected).
- [x] [MVP] Add user opt-in control for gateway mode.
- [x] [MVP] Add device condition checks (battery/network policy where feasible).

### 8.3 Sync behavior
- [x] [MVP] Upload pending events when gateway is active.
- [x] [MVP] Pull confirmations and remote updates.
- [x] [MVP] Store sync outcomes in `sync_jobs` history.
- [x] [HARDEN] Add backoff and dead-letter logic for repeated failures.

---

## 9) Background Processing

### 9.1 Scheduling
- [x] [MVP] Add scheduler abstraction and implementation.
- [x] [MVP] Mobile: integrate `workmanager` for periodic sync/cleanup.
- [x] [MVP] Desktop: add in-app periodic scheduler while app is active.

### 9.2 Jobs
- [x] [MVP] Queue retry job for pending bundles.
- [x] [MVP] Queue cleanup job for expired bundles.
- [x] [MVP] Queue sync job runner.

---

## 10) Crypto and Node Identity

### 10.1 Identity
- [x] [MVP] Generate persistent node keypair on first launch.
- [x] [MVP] Securely store private key.
- [x] [MVP] Expose public identity for peer trust/debug screens.

### 10.2 Bundle integrity
- [x] [MVP] Sign outbound bundles (Ed25519).
- [x] [MVP] Verify inbound bundle signatures.
- [x] [MVP] Reject/flag invalid signatures.

### 10.3 Security hardening
- [x] [HARDEN] Add anti-replay strategy.
- [x] [HARDEN] Add key rotation strategy (if required).

---

## 11) Feature: Wallet Events (Offline Token Actions)

### 11.1 MVP wallet model
- [ ] [POST-MVP] Define offline spend/receive event schema.
- [ ] [POST-MVP] Add local ledger event store.
- [ ] [POST-MVP] Add pending/reconciled/rejected transaction states.

### 11.2 Reconciliation
- [ ] [POST-MVP] Sync unresolved wallet events via gateway.
- [ ] [POST-MVP] Handle confirmation/rejection bundles.

---

## 12) Feature: Marketplace

### 12.1 Listings
- [ ] [POST-MVP] Define listing bundle and local listing projections.
- [ ] [POST-MVP] Create listing create/browse flow.

### 12.2 Orders
- [ ] [POST-MVP] Define order bundle and status model.
- [ ] [POST-MVP] Add order create/update/resolve flow.

---

## 13) Feature: Offline Search and Cached Web

### 13.1 Search metadata
- [ ] [POST-MVP] Define search request/index update bundle types.
- [ ] [POST-MVP] Store search index metadata.

### 13.2 Cached content view
- [ ] [POST-MVP] Add cached HTML/content fetch model.
- [ ] [POST-MVP] Render cached pages in webview.

---

## 14) UX, Navigation, and Design System

### 14.1 Navigation
- [x] [MVP] Add root router.
- [x] [MVP] Add route map for features (chat/files/settings/sync/status).

### 14.2 Design tokens and components
- [x] [MVP] Add initial compact theme baseline.
- [ ] [MVP] Extract typography/spacing/color tokens.
- [ ] [MVP] Build reusable status cards, chips, list tiles, and banners.

### 14.3 Accessibility and localization
- [ ] [HARDEN] Add semantics labels to key controls.
- [ ] [HARDEN] Validate text scaling and contrast.
- [ ] [POST-MVP] Add i18n scaffolding.

---

## 15) Platform and Permission Readiness

### 15.1 Android
- [ ] [MVP] Verify network/multicast permissions needed for discovery.
- [ ] [MVP] Verify background execution behavior for jobs.
- [ ] [DEMO] Validate two physical Android device demo run.

### 15.2 Windows
- [ ] [MVP] Validate sockets and local DB behavior on Windows.
- [ ] [DEMO] Validate two-instance local LAN simulation workflow.

### 15.3 iOS (secondary)
- [ ] [POST-MVP] Validate broadcast/discovery limitations and alternatives.
- [ ] [POST-MVP] Validate background task constraints.

---

## 16) Observability, Logging, and Diagnostics

### 16.1 Logging
- [x] [MVP] Add structured logger service.
- [x] [MVP] Log key runtime events (start/stop/discover/send/receive/ack).
- [x] [HARDEN] Add log levels and redaction policy.

### 16.2 Diagnostics UI
- [x] [DEMO] Add runtime diagnostics screen:
	- [x] discovered peers
	- [x] transport status
	- [x] queue metrics
	- [x] recent error events

---

## 17) Testing Strategy

### 17.1 Unit tests
- [ ] [MVP] Bundle serialization/deserialization tests.
- [ ] [MVP] Repository behavior tests.
- [x] [MVP] Content metadata repository tests.
- [x] [MVP] Runtime state transition tests.
- [x] [MVP] ACK state machine tests.

### 17.2 Integration tests
- [ ] [MVP] Two-node message exchange integration test harness.
- [ ] [MVP] Restart persistence test.
- [ ] [MVP] Discovery and peer registration test.

### 17.3 Widget tests
- [x] [MVP] Shell smoke test.
- [ ] [MVP] Node status interactions test.
- [ ] [MVP] Queue enqueue/ack UI tests.
- [ ] [MVP] Chat workflow widget tests.

### 17.4 Manual QA matrix
- [x] [DEMO] Create manual test scripts for Android + Windows.
- [x] [DEMO] Track known issues and severity.

---

## 18) Documentation and Academic Deliverables

### 18.1 Project documentation
- [x] [MVP] Replace boilerplate README with real project docs.
- [x] [MVP] Add architecture diagram and sequence diagrams.
- [x] [MVP] Add setup instructions for Android/Windows testing.

### 18.2 Technical report materials
- [ ] [DEMO] Capture architecture rationale and trade-offs.
- [ ] [DEMO] Document experiment/test results.
- [ ] [DEMO] Prepare limitations and future work section.

### 18.3 Demo assets
- [x] [DEMO] Create demo script with exact steps and timing.
- [ ] [DEMO] Record backup demo video.
- [ ] [DEMO] Prepare slides with proof screenshots/log snippets.

---

## 19) CI/CD and Release Readiness

### 19.1 Quality automation
- [x] [HARDEN] Add CI checks (`flutter analyze`, tests, codegen check).
- [x] [HARDEN] Fail CI if generated code is stale.

### 19.2 Build outputs
- [x] [DEMO] Create reproducible Android and Windows build commands.
- [x] [DEMO] Prepare release artifacts and version tags.

---

## 20) Immediate Next Steps (Do This In Order)

1. [x] [MVP] Implement explicit ACK bundles and ACK processing pipeline.
2. [x] [MVP] Build first real Chat vertical slice (composer + list + delivery states).
3. [x] [MVP] Replace broadcast discovery with mDNS/NSD adapter while keeping the same `DiscoveryAdapter` contract.
4. [x] [MVP] Add peer/contact persistence table and runtime peer history view.
5. [x] [MVP] Implement gateway sync contract (`DioSyncApi` + `SyncEngine`) with mocked server if backend is not ready.
6. [x] [DEMO] Produce first end-to-end demo script and rehearse on Android + Windows.
7. [x] [MVP] Add directed chat target selection (peer picker) and destination-based message routing.
8. [x] [MVP] Persist sync run outcomes in `sync_jobs` history and show recent sync history in UI.
9. [x] [MVP] Add sync backoff/dead-letter behavior for repeated failures.
10. [x] [MVP] Add `messages` projection table for chat query performance and richer message metadata.

---

## 21) Definition of Done (Final Semester MVP)

- [ ] [MVP] Two nodes can discover each other locally.
- [ ] [MVP] One node sends a chat message offline and the other receives it.
- [ ] [MVP] Bundle queue persists across app restarts.
- [ ] [MVP] ACK bundle clears pending item deterministically.
- [ ] [MVP] File metadata bundle flow works.
- [x] [MVP] Gateway sync executes when internet appears and user allows it.
- [ ] [MVP] Android and Windows demo passes with a written runbook.
- [ ] [MVP] README + report artifacts are complete enough for assessment.

