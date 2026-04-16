# Architecture Boundaries

This document defines layer ownership and import direction for OffLiMU.

## Goals

- Keep business logic independent from framework and platform details.
- Prevent accidental cross-layer coupling.
- Keep feature code easy to evolve and test.

## Layers

- `domain/`: Pure business entities, repository/service contracts, use-cases.
- `infrastructure/`: Implementations for contracts (DB, transport, discovery, settings, platform adapters).
- `node_runtime/`: Runtime orchestration over domain contracts (routing, forwarding, ACK flow, retries, telemetry).
- `core/`: App-wide shared wiring and primitives (DI providers, theme, global error handling).
- `features/`: UI and presentation logic for user-visible flows.
- `app/`: Flutter app shell and routing composition.

## Import Rules

Allowed imports by layer:

- `domain/` may import only:
  - Dart SDK
  - other files in `domain/`
- `infrastructure/` may import:
  - `domain/`
  - `core/` only for cross-cutting primitives that are framework-agnostic (avoid UI deps)
  - `node_runtime/` only for runtime orchestration in headless/background execution paths
  - Dart/Flutter and third-party packages needed for implementation details
- `node_runtime/` may import:
  - `domain/`
  - `core/` cross-cutting utilities only when needed
  - must not import `features/` or `app/`
- `core/` may import:
  - `domain/`, `infrastructure/`, and `node_runtime/` for app composition and dependency wiring
  - must not import `features/`
- `features/` may import:
  - `domain/` (UI models/use-case types)
  - `core/` (providers/theme/error hooks)
  - must not import `infrastructure/` directly
- `app/` may import:
  - `core/`
  - `features/`

Forbidden directions:

- `domain/` -> `infrastructure/`, `node_runtime/`, `features/`, `core/`, `app/`
- `features/` -> `infrastructure/`
- `core/` -> `features/`
- `node_runtime/` -> `features/`, `app/`

## Dependency Flow

Use this dependency direction as the default:

`app -> features -> core -> node_runtime -> domain`

`core -> infrastructure -> domain`

`node_runtime -> domain`

`features -> domain`

## Practical Guidelines

- If UI needs data or behavior, add a provider/use-case exposure in `core/di/providers.dart` instead of importing infrastructure implementation in a feature.
- Keep platform/plugin APIs in `infrastructure/`.
- Keep serialization and storage mapping in `infrastructure/`.
- Keep routing and screen composition in `app/` and `features/`.

## Review Checklist

- New file placed in the correct layer.
- Imports follow allowed rules above.
- No direct `features/` <-> `infrastructure/` coupling.
- Domain code remains framework-free.

## Future Enforcement

Boundary enforcement is now active via an automated architecture test:

- `test/architecture/import_boundaries_test.dart`

The next hardening step is adding analyzer/lint plugin rules for editor-time feedback.
This remains tracked separately in TODO as:

- `[HARDEN] Add lint/import rules to reduce cross-layer leaks.`
