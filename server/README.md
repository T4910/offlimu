# OffLiMU Sync Server

TypeScript sync server for OffLiMU gateway reconciliation.

## Stack

- Fastify HTTP API
- Zod wire validation
- Postgres persistence via Kysely
- Ed25519 bundle verification/signing via `tweetnacl`
- Vitest test suite

## API

- `POST /sync/upload`
  - Body: `{ "bundles": [...] }`
  - Response: `{ "acknowledgedBundleIds": [], "rejections": [], "webSearchResults": [] }`
- `GET /sync/fetch?sinceMs=0`
  - Response: `{ "bundles": [...] }`

The JSON shape intentionally matches the current Flutter `DioSyncApi`.

## Local Setup

```sh
cd server
pnpm install
cp .env.example .env
```

Create a Postgres database and apply:

```sh
psql "$DATABASE_URL" -f migrations/001_initial.sql
```

Run:

```sh
pnpm dev
```

For Flutter client testing, run the app with:

```sh
--dart-define=OFFLIMU_SYNC_MOCK=false
--dart-define=OFFLIMU_SYNC_BASE_URL=http://localhost:7774
```

## Web Search

The server defaults to deterministic mock web results. To use Google
Programmable Search JSON API for candidate URLs, set:

```sh
WEB_SEARCH_PROVIDER=google
GOOGLE_CSE_API_KEY=...
GOOGLE_CSE_ID=...
```

Fetched result pages are bounded, robots-aware, sanitized HTML snapshots. Pages
that cannot be scraped still return fallback HTML with a clear error reason.

## Tests

```sh
pnpm test
pnpm typecheck
```

The tests use the in-memory store so Postgres is not required for normal CI.
