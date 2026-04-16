# Schema Migration Policy

This document defines how SQLite schema changes are handled in OffLiMU.

## Goals

- Preserve user data across app upgrades.
- Keep migrations deterministic and repeatable.
- Make schema evolution testable in CI.

## Rules

1. Only additive changes in normal upgrades: add columns with safe defaults, add tables/indexes.
2. Never drop or rewrite existing user rows inside `onUpgrade` without a backup + explicit migration plan.
3. Every schema bump must:
- increment `schemaVersion` in `lib/infrastructure/db/app_database.dart`
- add a guarded migration block (`if (from < X) { ... }`)
- include migration tests under `test/infrastructure/db/`
4. New nullable columns are preferred for backwards compatibility.
5. New non-null columns must provide a default value so legacy rows remain valid.

## Test Requirements

For each schema bump:

1. Add a test that opens an older schema and migrates to latest.
2. Assert newly added columns/tables exist after migration.
3. Assert at least one legacy row survives migration with expected defaults.
4. Add a fresh-schema sanity test for latest `schemaVersion`.

## Operational Notes

- Keep migrations idempotent by version guard.
- Avoid expensive transformations in UI-critical startup paths.
- If destructive changes are required, stage them across versions and provide data export or fallback.
