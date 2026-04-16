# OffLiMU

OffLiMU is an offline-first, delay-tolerant messaging and file-sharing runtime built with Flutter.

## What It Demonstrates

- Local peer discovery and TCP bundle transport.
- Persistent bundle queue with ACK-driven state transitions.
- Offline chat and resumable file transfer.
- Optional gateway sync for reconciliation when internet is reachable.
- Runtime diagnostics for peers, queue, transport, sync, and recent errors.

## Architecture

- [Architecture Boundaries](docs/architecture-boundaries.md)
- [Scope Lock Spec](docs/scope-lock-spec.md)
- [Architecture and Sequence Diagrams](docs/architecture-diagrams.md)

## Demo and Launch Docs

- [Demo Pass/Fail Checklist](docs/demo-pass-fail-checklist.md)
- [Launch Workflows](docs/launch-workflows.md)
- [End-to-End Demo Runbook](docs/end-to-end-demo-runbook.md)
- [Android and Windows Setup](docs/setup-android-windows.md)
- [Reproducible Build Commands](docs/build-commands.md)
- [Manual QA Matrix](docs/manual-qa-matrix.md)
- [Known Issues Log](docs/known-issues-log.md)
- [Report Materials Outline](docs/report-materials-outline.md)

## Quick Start

```bash
flutter pub get
flutter run
```

## Two-Node Local Demo

Use two terminals from repo root:

```bash
bash scripts/run_local_node_a.sh
```

```bash
bash scripts/run_local_node_b.sh
```

## Quality Gates

```bash
bash scripts/verify_codegen.sh
flutter analyze
flutter test
```
