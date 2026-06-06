CREATE TABLE IF NOT EXISTS uploaded_bundles (
  bundle_id TEXT PRIMARY KEY,
  bundle_json JSONB NOT NULL,
  source_node_id TEXT NOT NULL,
  type TEXT NOT NULL,
  signature_valid BOOLEAN NOT NULL,
  processing_status TEXT NOT NULL,
  first_seen_ms BIGINT NOT NULL,
  last_seen_ms BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS processed_bundle_ids (
  bundle_id TEXT PRIMARY KEY,
  processed_at_ms BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS wallet_ledger_events (
  event_id TEXT PRIMARY KEY,
  node_id TEXT NOT NULL,
  counterparty_node_id TEXT,
  kind TEXT NOT NULL,
  amount_minor_units BIGINT NOT NULL,
  balance_impact_minor_units BIGINT NOT NULL,
  status TEXT NOT NULL,
  source_bundle_id TEXT,
  memo TEXT,
  created_at_ms BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS wallet_ledger_node_idx ON wallet_ledger_events(node_id, created_at_ms);
CREATE INDEX IF NOT EXISTS wallet_ledger_source_idx ON wallet_ledger_events(source_bundle_id);

CREATE TABLE IF NOT EXISTS outbox_bundles (
  bundle_id TEXT PRIMARY KEY,
  bundle_json JSONB NOT NULL,
  created_at_ms BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS outbox_bundles_created_idx ON outbox_bundles(created_at_ms);

CREATE TABLE IF NOT EXISTS sync_audit_events (
  id BIGSERIAL PRIMARY KEY,
  event_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  bundle_id TEXT,
  node_id TEXT,
  message TEXT NOT NULL,
  created_at_ms BIGINT NOT NULL,
  fields_json JSONB
);

CREATE TABLE IF NOT EXISTS web_search_requests (
  bundle_id TEXT PRIMARY KEY,
  requester_node_id TEXT NOT NULL,
  query TEXT NOT NULL,
  normalized_query TEXT NOT NULL,
  max_results INTEGER NOT NULL,
  status TEXT NOT NULL,
  created_at_ms BIGINT NOT NULL,
  UNIQUE(requester_node_id, normalized_query)
);

CREATE TABLE IF NOT EXISTS web_search_results (
  id TEXT PRIMARY KEY,
  request_bundle_id TEXT NOT NULL REFERENCES web_search_requests(bundle_id),
  query TEXT NOT NULL,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  snippet TEXT NOT NULL,
  html TEXT NOT NULL,
  content_hash TEXT NOT NULL,
  byte_size BIGINT NOT NULL,
  status TEXT NOT NULL,
  error TEXT,
  created_at_ms BIGINT NOT NULL
);
