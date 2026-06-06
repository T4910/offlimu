import type { Bundle } from '../types/bundle.js';

export type UploadedBundleRecord = {
  bundleId: string;
  bundle: Bundle;
  sourceNodeId: string;
  type: string;
  signatureValid: boolean;
  processingStatus: 'accepted' | 'rejected' | 'duplicate';
  firstSeenMs: number;
  lastSeenMs: number;
};

export type WalletLedgerEvent = {
  eventId: string;
  nodeId: string;
  counterpartyNodeId?: string | null;
  kind: 'opening_grant' | 'spend' | 'confirmation' | 'rejection' | 'relay_reward' | 'gateway_reward';
  amountMinorUnits: number;
  balanceImpactMinorUnits: number;
  status: 'pending' | 'confirmed' | 'rejected';
  sourceBundleId?: string | null;
  memo?: string | null;
  createdAtMs: number;
};

export type AuditEvent = {
  id: string;
  kind: string;
  bundleId?: string | null;
  nodeId?: string | null;
  message: string;
  createdAtMs: number;
  fields?: Record<string, unknown>;
};

export type WebSearchRequestRecord = {
  bundleId: string;
  requesterNodeId: string;
  query: string;
  normalizedQuery: string;
  maxResults: number;
  status: 'pending' | 'completed' | 'failed';
  createdAtMs: number;
};

export type WebSearchResultRecord = {
  id: string;
  requestBundleId: string;
  query: string;
  title: string;
  url: string;
  snippet: string;
  html: string;
  contentHash: string;
  byteSize: number;
  status: 'completed' | 'failed';
  error?: string | null;
  createdAtMs: number;
};

export interface SyncStore {
  saveUploadedBundle(record: UploadedBundleRecord): Promise<void>;
  getUploadedBundle(bundleId: string): Promise<UploadedBundleRecord | undefined>;
  hasProcessedBundle(bundleId: string): Promise<boolean>;
  markProcessedBundle(bundleId: string): Promise<void>;

  appendWalletEvent(event: WalletLedgerEvent): Promise<void>;
  listWalletEvents(nodeId?: string): Promise<WalletLedgerEvent[]>;
  findWalletEventBySource(sourceBundleId: string, kind?: WalletLedgerEvent['kind']): Promise<WalletLedgerEvent | undefined>;

  appendOutboxBundle(bundle: Bundle): Promise<void>;
  fetchOutboxBundlesSince(sinceMs: number): Promise<Bundle[]>;

  appendAuditEvent(event: AuditEvent): Promise<void>;
  listAuditEvents(): Promise<AuditEvent[]>;

  upsertWebSearchRequest(record: WebSearchRequestRecord): Promise<WebSearchRequestRecord>;
  findWebSearchRequestByDedupe(requesterNodeId: string, normalizedQuery: string): Promise<WebSearchRequestRecord | undefined>;
  appendWebSearchResults(results: WebSearchResultRecord[]): Promise<void>;
  listWebSearchResults(requestBundleId: string): Promise<WebSearchResultRecord[]>;
}
