# OffLiMU Scope Lock (MVP + Demo)

## In Scope (Semester MVP)

- LAN discovery between two nodes (NSD/mDNS with LAN broadcast fallback).
- TCP transport with framed bundles and retry behavior.
- Bundle queue persistence with ACK transitions.
- Offline chat (send/receive, delivery state, conversation view).
- File metadata and chunk transfer with resume support and progress UI.
- Gateway sync flow with user control and condition checks.
- Runtime status and diagnostics surfaces in app UI.

## Out of Scope (For This Semester)

- Wallet event reconciliation and token operations.
- Marketplace listings and order flows.
- Offline search indexing and cached web rendering.
- Production key rotation and advanced anti-replay guarantees.

## Definition of Done (Demo-Oriented)

- Two nodes discover each other on a shared LAN/hotspot.
- Node A can send offline chat to Node B.
- Pending bundles survive restart and continue processing.
- ACK processing clears pending sender items deterministically.
- File metadata/chunk path completes and persists content metadata.
- Gateway sync runs when internet becomes reachable and user opt-in is enabled.

## Risks and Mitigations

- Discovery differences across platforms:
  - Mitigation: keep NSD/mDNS + broadcast fallback and a known-good hotspot path.
- Background restrictions on mobile:
  - Mitigation: keep manual sync and in-app scheduler fallback for demo flow.
- Runtime config drift between nodes:
  - Mitigation: launch profiles with explicit node ID, ports, and sync flags.
