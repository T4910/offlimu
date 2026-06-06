import type { Kysely } from 'kysely';
import type { Bundle } from '../types/bundle.js';
import type { Database } from './schema.js';
import type {
  AuditEvent,
  AuditEventFilters,
  OutboxBundleFilters,
  SyncStore,
  UploadedBundleRecord,
  UploadedBundleFilters,
  WalletLedgerEvent,
  WalletLedgerFilters,
  WebSearchRequestRecord,
  WebSearchRequestFilters,
  WebSearchResultRecord,
  WebSearchResultFilters
} from './store.js';

export class KyselySyncStore implements SyncStore {
  constructor(private readonly db: Kysely<Database>) {}

  async saveUploadedBundle(record: UploadedBundleRecord): Promise<void> {
    await this.db
      .insertInto('uploaded_bundles')
      .values({
        bundle_id: record.bundleId,
        bundle_json: record.bundle,
        source_node_id: record.sourceNodeId,
        type: record.type,
        signature_valid: record.signatureValid,
        processing_status: record.processingStatus,
        first_seen_ms: record.firstSeenMs,
        last_seen_ms: record.lastSeenMs
      })
      .onConflict((oc) =>
        oc.column('bundle_id').doUpdateSet({ last_seen_ms: record.lastSeenMs })
      )
      .execute();
  }

  async getUploadedBundle(bundleId: string): Promise<UploadedBundleRecord | undefined> {
    const row = await this.db.selectFrom('uploaded_bundles').selectAll().where('bundle_id', '=', bundleId).executeTakeFirst();
    return row
      ? {
          bundleId: row.bundle_id,
          bundle: row.bundle_json as Bundle,
          sourceNodeId: row.source_node_id,
          type: row.type,
          signatureValid: row.signature_valid,
          processingStatus: row.processing_status as UploadedBundleRecord['processingStatus'],
          firstSeenMs: toNumber(row.first_seen_ms),
          lastSeenMs: toNumber(row.last_seen_ms)
        }
      : undefined;
  }

  async listUploadedBundles(filters: UploadedBundleFilters = {}): Promise<UploadedBundleRecord[]> {
    let query = this.db.selectFrom('uploaded_bundles').selectAll();
    if (filters.type) query = query.where('type', '=', filters.type);
    if (filters.processingStatus) query = query.where('processing_status', '=', filters.processingStatus);
    if (filters.signatureValid !== undefined) query = query.where('signature_valid', '=', filters.signatureValid);
    const rows = await query
      .orderBy('last_seen_ms desc')
      .limit(normalizeLimit(filters.limit))
      .execute();
    return rows.map((row) => ({
      bundleId: row.bundle_id,
      bundle: row.bundle_json as Bundle,
      sourceNodeId: row.source_node_id,
      type: row.type,
      signatureValid: row.signature_valid,
      processingStatus: row.processing_status as UploadedBundleRecord['processingStatus'],
      firstSeenMs: toNumber(row.first_seen_ms),
      lastSeenMs: toNumber(row.last_seen_ms)
    }));
  }

  async hasProcessedBundle(bundleId: string): Promise<boolean> {
    const row = await this.db.selectFrom('processed_bundle_ids').select('bundle_id').where('bundle_id', '=', bundleId).executeTakeFirst();
    return Boolean(row);
  }

  async markProcessedBundle(bundleId: string): Promise<void> {
    await this.db
      .insertInto('processed_bundle_ids')
      .values({ bundle_id: bundleId, processed_at_ms: Date.now() })
      .onConflict((oc) => oc.column('bundle_id').doNothing())
      .execute();
  }

  async appendWalletEvent(event: WalletLedgerEvent): Promise<void> {
    await this.db
      .insertInto('wallet_ledger_events')
      .values({
        event_id: event.eventId,
        node_id: event.nodeId,
        counterparty_node_id: event.counterpartyNodeId ?? null,
        kind: event.kind,
        amount_minor_units: event.amountMinorUnits,
        balance_impact_minor_units: event.balanceImpactMinorUnits,
        status: event.status,
        source_bundle_id: event.sourceBundleId ?? null,
        memo: event.memo ?? null,
        created_at_ms: event.createdAtMs
      })
      .onConflict((oc) => oc.column('event_id').doNothing())
      .execute();
  }

  async listWalletEvents(filters?: string | WalletLedgerFilters): Promise<WalletLedgerEvent[]> {
    const normalized = typeof filters === 'string' ? { nodeId: filters } : filters ?? {};
    let query = this.db.selectFrom('wallet_ledger_events').selectAll();
    if (normalized.nodeId) query = query.where('node_id', '=', normalized.nodeId);
    if (normalized.kind) query = query.where('kind', '=', normalized.kind);
    if (normalized.status) query = query.where('status', '=', normalized.status);
    const rows = await query
      .orderBy('created_at_ms desc')
      .limit(normalizeLimit(normalized.limit))
      .execute();
    return rows.map((row) => ({
      eventId: row.event_id,
      nodeId: row.node_id,
      counterpartyNodeId: row.counterparty_node_id,
      kind: row.kind as WalletLedgerEvent['kind'],
      amountMinorUnits: toNumber(row.amount_minor_units),
      balanceImpactMinorUnits: toNumber(row.balance_impact_minor_units),
      status: row.status as WalletLedgerEvent['status'],
      sourceBundleId: row.source_bundle_id,
      memo: row.memo,
      createdAtMs: toNumber(row.created_at_ms)
    }));
  }

  async findWalletEventBySource(sourceBundleId: string, kind?: WalletLedgerEvent['kind']): Promise<WalletLedgerEvent | undefined> {
    const events = await this.listWalletEvents();
    return events.find((event) => event.sourceBundleId === sourceBundleId && (!kind || event.kind === kind));
  }

  async appendOutboxBundle(bundle: Bundle): Promise<void> {
    await this.db
      .insertInto('outbox_bundles')
      .values({ bundle_id: bundle.bundleId, bundle_json: bundle, created_at_ms: bundle.createdAtMs })
      .onConflict((oc) => oc.column('bundle_id').doNothing())
      .execute();
  }

  async fetchOutboxBundlesSince(sinceMs: number): Promise<Bundle[]> {
    const rows = await this.db
      .selectFrom('outbox_bundles')
      .selectAll()
      .where('created_at_ms', '>', sinceMs)
      .orderBy('created_at_ms asc')
      .execute();
    return rows.map((row) => row.bundle_json as Bundle);
  }

  async listOutboxBundles(filters: OutboxBundleFilters = {}): Promise<Bundle[]> {
    let query = this.db.selectFrom('outbox_bundles').selectAll();
    if (filters.type) {
      query = query.where('bundle_json', '@>', { type: filters.type });
    }
    if (filters.destinationNodeId) {
      query = query.where('bundle_json', '@>', { destinationNodeId: filters.destinationNodeId });
    }
    const rows = await query
      .orderBy('created_at_ms desc')
      .limit(normalizeLimit(filters.limit))
      .execute();
    return rows.map((row) => row.bundle_json as Bundle);
  }

  async appendAuditEvent(event: AuditEvent): Promise<void> {
    await this.db.insertInto('sync_audit_events').values({
      event_id: event.id,
      kind: event.kind,
      bundle_id: event.bundleId ?? null,
      node_id: event.nodeId ?? null,
      message: event.message,
      created_at_ms: event.createdAtMs,
      fields_json: event.fields ?? null
    }).execute();
  }

  async listAuditEvents(filters: AuditEventFilters = {}): Promise<AuditEvent[]> {
    let query = this.db.selectFrom('sync_audit_events').selectAll();
    if (filters.kind) query = query.where('kind', '=', filters.kind);
    if (filters.nodeId) query = query.where('node_id', '=', filters.nodeId);
    const rows = await query
      .orderBy('created_at_ms desc')
      .limit(normalizeLimit(filters.limit))
      .execute();
    return rows.map((row) => ({
      id: row.event_id,
      kind: row.kind,
      bundleId: row.bundle_id,
      nodeId: row.node_id,
      message: row.message,
      createdAtMs: toNumber(row.created_at_ms),
      fields: (row.fields_json as Record<string, unknown> | null) ?? undefined
    }));
  }

  async upsertWebSearchRequest(record: WebSearchRequestRecord): Promise<WebSearchRequestRecord> {
    const existing = await this.findWebSearchRequestByDedupe(record.requesterNodeId, record.normalizedQuery);
    if (existing) return existing;
    await this.db.insertInto('web_search_requests').values({
      bundle_id: record.bundleId,
      requester_node_id: record.requesterNodeId,
      query: record.query,
      normalized_query: record.normalizedQuery,
      max_results: record.maxResults,
      status: record.status,
      created_at_ms: record.createdAtMs
    }).onConflict((oc) => oc.column('bundle_id').doNothing()).execute();
    return record;
  }

  async findWebSearchRequestByDedupe(requesterNodeId: string, normalizedQuery: string): Promise<WebSearchRequestRecord | undefined> {
    const row = await this.db
      .selectFrom('web_search_requests')
      .selectAll()
      .where('requester_node_id', '=', requesterNodeId)
      .where('normalized_query', '=', normalizedQuery)
      .executeTakeFirst();
    return row
      ? {
          bundleId: row.bundle_id,
          requesterNodeId: row.requester_node_id,
          query: row.query,
          normalizedQuery: row.normalized_query,
          maxResults: row.max_results,
          status: row.status as WebSearchRequestRecord['status'],
          createdAtMs: toNumber(row.created_at_ms)
        }
      : undefined;
  }

  async listWebSearchRequests(filters: WebSearchRequestFilters = {}): Promise<WebSearchRequestRecord[]> {
    let query = this.db.selectFrom('web_search_requests').selectAll();
    if (filters.requesterNodeId) query = query.where('requester_node_id', '=', filters.requesterNodeId);
    if (filters.status) query = query.where('status', '=', filters.status);
    if (filters.query) {
      const pattern = `%${filters.query.toLowerCase()}%`;
      query = query.where((eb) =>
        eb.or([
          eb('normalized_query', 'like', pattern),
          eb('query', 'ilike', `%${filters.query}%`)
        ])
      );
    }
    const rows = await query
      .orderBy('created_at_ms desc')
      .limit(normalizeLimit(filters.limit))
      .execute();
    return rows.map((row) => ({
      bundleId: row.bundle_id,
      requesterNodeId: row.requester_node_id,
      query: row.query,
      normalizedQuery: row.normalized_query,
      maxResults: row.max_results,
      status: row.status as WebSearchRequestRecord['status'],
      createdAtMs: toNumber(row.created_at_ms)
    }));
  }

  async appendWebSearchResults(results: WebSearchResultRecord[]): Promise<void> {
    for (const result of results) {
      await this.db.insertInto('web_search_results').values({
        id: result.id,
        request_bundle_id: result.requestBundleId,
        query: result.query,
        title: result.title,
        url: result.url,
        snippet: result.snippet,
        html: result.html,
        content_hash: result.contentHash,
        byte_size: result.byteSize,
        status: result.status,
        error: result.error ?? null,
        created_at_ms: result.createdAtMs
      }).onConflict((oc) => oc.column('id').doNothing()).execute();
    }
  }

  async listWebSearchResults(filters?: string | WebSearchResultFilters): Promise<WebSearchResultRecord[]> {
    const normalized = typeof filters === 'string' ? { requestBundleId: filters } : filters ?? {};
    let query = this.db.selectFrom('web_search_results').selectAll();
    if (normalized.requestBundleId) query = query.where('request_bundle_id', '=', normalized.requestBundleId);
    if (normalized.status) query = query.where('status', '=', normalized.status);
    if (normalized.query) {
      query = query.where((eb) =>
        eb.or([
          eb('query', 'ilike', `%${normalized.query}%`),
          eb('title', 'ilike', `%${normalized.query}%`)
        ])
      );
    }
    const rows = await query
      .orderBy('created_at_ms desc')
      .limit(normalizeLimit(normalized.limit))
      .execute();
    return rows.map((row) => ({
      id: row.id,
      requestBundleId: row.request_bundle_id,
      query: row.query,
      title: row.title,
      url: row.url,
      snippet: row.snippet,
      html: row.html,
      contentHash: row.content_hash,
      byteSize: toNumber(row.byte_size),
      status: row.status as WebSearchResultRecord['status'],
      error: row.error,
      createdAtMs: toNumber(row.created_at_ms)
    }));
  }
}

function normalizeLimit(limit?: number): number {
  if (limit === undefined || !Number.isFinite(limit) || limit <= 0) {
    return 100;
  }
  return Math.min(Math.trunc(limit), 500);
}

function toNumber(value: unknown): number {
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'bigint') {
    return Number(value);
  }
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}
