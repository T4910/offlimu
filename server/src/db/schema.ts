import type { ColumnType, Generated, Insertable, Selectable } from 'kysely';

type JsonValue = ColumnType<unknown, unknown, unknown>;

export interface Database {
  uploaded_bundles: {
    bundle_id: string;
    bundle_json: JsonValue;
    source_node_id: string;
    type: string;
    signature_valid: boolean;
    processing_status: string;
    first_seen_ms: number;
    last_seen_ms: number;
  };
  processed_bundle_ids: {
    bundle_id: string;
    processed_at_ms: number;
  };
  wallet_ledger_events: {
    event_id: string;
    node_id: string;
    counterparty_node_id: string | null;
    kind: string;
    amount_minor_units: number;
    balance_impact_minor_units: number;
    status: string;
    source_bundle_id: string | null;
    memo: string | null;
    created_at_ms: number;
  };
  outbox_bundles: {
    bundle_id: string;
    bundle_json: JsonValue;
    created_at_ms: number;
  };
  sync_audit_events: {
    id: Generated<number>;
    event_id: string;
    kind: string;
    bundle_id: string | null;
    node_id: string | null;
    message: string;
    created_at_ms: number;
    fields_json: JsonValue | null;
  };
  web_search_requests: {
    bundle_id: string;
    requester_node_id: string;
    query: string;
    normalized_query: string;
    max_results: number;
    status: string;
    created_at_ms: number;
  };
  web_search_results: {
    id: string;
    request_bundle_id: string;
    query: string;
    title: string;
    url: string;
    snippet: string;
    html: string;
    content_hash: string;
    byte_size: number;
    status: string;
    error: string | null;
    created_at_ms: number;
  };
}

export type UploadedBundleRow = Selectable<Database['uploaded_bundles']>;
export type NewUploadedBundleRow = Insertable<Database['uploaded_bundles']>;
