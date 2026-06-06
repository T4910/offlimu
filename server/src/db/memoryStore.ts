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
import type { Bundle } from '../types/bundle.js';

export class MemorySyncStore implements SyncStore {
  private uploaded = new Map<string, UploadedBundleRecord>();
  private processed = new Set<string>();
  private walletEvents: WalletLedgerEvent[] = [];
  private outbox = new Map<string, Bundle>();
  private auditEvents: AuditEvent[] = [];
  private webRequests = new Map<string, WebSearchRequestRecord>();
  private webResults: WebSearchResultRecord[] = [];

  async saveUploadedBundle(record: UploadedBundleRecord): Promise<void> {
    const existing = this.uploaded.get(record.bundleId);
    this.uploaded.set(record.bundleId, existing ? { ...existing, lastSeenMs: record.lastSeenMs } : record);
  }

  async getUploadedBundle(bundleId: string): Promise<UploadedBundleRecord | undefined> {
    return this.uploaded.get(bundleId);
  }

  async listUploadedBundles(filters: UploadedBundleFilters = {}): Promise<UploadedBundleRecord[]> {
    return applyLimit(
      [...this.uploaded.values()]
        .filter((record) => !filters.type || record.type === filters.type)
        .filter((record) => !filters.processingStatus || record.processingStatus === filters.processingStatus)
        .filter((record) => filters.signatureValid === undefined || record.signatureValid === filters.signatureValid)
        .sort((a, b) => b.lastSeenMs - a.lastSeenMs),
      filters.limit
    );
  }

  async hasProcessedBundle(bundleId: string): Promise<boolean> {
    return this.processed.has(bundleId);
  }

  async markProcessedBundle(bundleId: string): Promise<void> {
    this.processed.add(bundleId);
  }

  async appendWalletEvent(event: WalletLedgerEvent): Promise<void> {
    if (!this.walletEvents.some((existing) => existing.eventId === event.eventId)) {
      this.walletEvents.push(event);
    }
  }

  async listWalletEvents(filters?: string | WalletLedgerFilters): Promise<WalletLedgerEvent[]> {
    const normalized = typeof filters === 'string' ? { nodeId: filters } : filters ?? {};
    const events = this.walletEvents
      .filter((event) => !normalized.nodeId || event.nodeId === normalized.nodeId)
      .filter((event) => !normalized.kind || event.kind === normalized.kind)
      .filter((event) => !normalized.status || event.status === normalized.status)
      .sort((a, b) => b.createdAtMs - a.createdAtMs);
    return applyLimit(events, normalized.limit);
  }

  async findWalletEventBySource(sourceBundleId: string, kind?: WalletLedgerEvent['kind']): Promise<WalletLedgerEvent | undefined> {
    return this.walletEvents.find(
      (event) => event.sourceBundleId === sourceBundleId && (!kind || event.kind === kind)
    );
  }

  async appendOutboxBundle(bundle: Bundle): Promise<void> {
    this.outbox.set(bundle.bundleId, bundle);
  }

  async fetchOutboxBundlesSince(sinceMs: number): Promise<Bundle[]> {
    return [...this.outbox.values()]
      .filter((bundle) => bundle.createdAtMs > sinceMs)
      .sort((a, b) => a.createdAtMs - b.createdAtMs);
  }

  async listOutboxBundles(filters: OutboxBundleFilters = {}): Promise<Bundle[]> {
    return applyLimit(
      [...this.outbox.values()]
        .filter((bundle) => !filters.type || bundle.type === filters.type)
        .filter((bundle) => !filters.destinationNodeId || bundle.destinationNodeId === filters.destinationNodeId)
        .sort((a, b) => b.createdAtMs - a.createdAtMs),
      filters.limit
    );
  }

  async appendAuditEvent(event: AuditEvent): Promise<void> {
    this.auditEvents.push(event);
  }

  async listAuditEvents(filters: AuditEventFilters = {}): Promise<AuditEvent[]> {
    return applyLimit(
      this.auditEvents
        .filter((event) => !filters.kind || event.kind === filters.kind)
        .filter((event) => !filters.nodeId || event.nodeId === filters.nodeId)
        .sort((a, b) => b.createdAtMs - a.createdAtMs),
      filters.limit
    );
  }

  async upsertWebSearchRequest(record: WebSearchRequestRecord): Promise<WebSearchRequestRecord> {
    const dedupeKey = `${record.requesterNodeId}:${record.normalizedQuery}`;
    const existing = this.webRequests.get(dedupeKey);
    if (existing) return existing;
    this.webRequests.set(dedupeKey, record);
    return record;
  }

  async findWebSearchRequestByDedupe(requesterNodeId: string, normalizedQuery: string): Promise<WebSearchRequestRecord | undefined> {
    return this.webRequests.get(`${requesterNodeId}:${normalizedQuery}`);
  }

  async listWebSearchRequests(filters: WebSearchRequestFilters = {}): Promise<WebSearchRequestRecord[]> {
    const query = filters.query?.toLowerCase();
    return applyLimit(
      [...this.webRequests.values()]
        .filter((request) => !filters.requesterNodeId || request.requesterNodeId === filters.requesterNodeId)
        .filter((request) => !filters.status || request.status === filters.status)
        .filter((request) => !query || request.normalizedQuery.includes(query) || request.query.toLowerCase().includes(query))
        .sort((a, b) => b.createdAtMs - a.createdAtMs),
      filters.limit
    );
  }

  async appendWebSearchResults(results: WebSearchResultRecord[]): Promise<void> {
    for (const result of results) {
      if (!this.webResults.some((existing) => existing.id === result.id)) {
        this.webResults.push(result);
      }
    }
  }

  async listWebSearchResults(filters?: string | WebSearchResultFilters): Promise<WebSearchResultRecord[]> {
    const normalized = typeof filters === 'string' ? { requestBundleId: filters } : filters ?? {};
    const query = normalized.query?.toLowerCase();
    return applyLimit(
      this.webResults
        .filter((result) => !normalized.requestBundleId || result.requestBundleId === normalized.requestBundleId)
        .filter((result) => !normalized.status || result.status === normalized.status)
        .filter((result) => !query || result.query.toLowerCase().includes(query) || result.title.toLowerCase().includes(query))
        .sort((a, b) => b.createdAtMs - a.createdAtMs),
      normalized.limit
    );
  }
}

function applyLimit<T>(items: T[], limit?: number): T[] {
  if (limit === undefined || limit <= 0) {
    return items;
  }
  return items.slice(0, limit);
}
