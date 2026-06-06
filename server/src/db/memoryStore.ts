import type {
  AuditEvent,
  SyncStore,
  UploadedBundleRecord,
  WalletLedgerEvent,
  WebSearchRequestRecord,
  WebSearchResultRecord
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

  async listWalletEvents(nodeId?: string): Promise<WalletLedgerEvent[]> {
    const events = nodeId
      ? this.walletEvents.filter((event) => event.nodeId === nodeId)
      : this.walletEvents;
    return [...events].sort((a, b) => a.createdAtMs - b.createdAtMs);
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

  async appendAuditEvent(event: AuditEvent): Promise<void> {
    this.auditEvents.push(event);
  }

  async listAuditEvents(): Promise<AuditEvent[]> {
    return [...this.auditEvents];
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

  async appendWebSearchResults(results: WebSearchResultRecord[]): Promise<void> {
    for (const result of results) {
      if (!this.webResults.some((existing) => existing.id === result.id)) {
        this.webResults.push(result);
      }
    }
  }

  async listWebSearchResults(requestBundleId: string): Promise<WebSearchResultRecord[]> {
    return this.webResults.filter((result) => result.requestBundleId === requestBundleId);
  }
}
