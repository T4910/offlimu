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
npm install
cp .env.example .env
```

Create a Postgres database and apply:

```sh
psql "$DATABASE_URL" -f migrations/001_initial.sql
```

Run:

```sh
npm run dev
```

For Flutter client testing, run the app with:

```sh
--dart-define=OFFLIMU_SYNC_MOCK=false
--dart-define=OFFLIMU_SYNC_BASE_URL=http://localhost:7774
```

## Tests

```sh
npm test
npm run typecheck
```

The tests use the in-memory store so Postgres is not required for normal CI.
