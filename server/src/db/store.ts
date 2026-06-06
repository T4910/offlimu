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

export type UploadedBundleFilters = {
  limit?: number;
  type?: string;
  processingStatus?: UploadedBundleRecord['processingStatus'];
  signatureValid?: boolean;
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

export type WalletLedgerFilters = {
  limit?: number;
  nodeId?: string;
  kind?: WalletLedgerEvent['kind'];
  status?: WalletLedgerEvent['status'];
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

export type AuditEventFilters = {
  limit?: number;
  kind?: string;
  nodeId?: string;
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

export type WebSearchRequestFilters = {
  limit?: number;
  requesterNodeId?: string;
  status?: WebSearchRequestRecord['status'];
  query?: string;
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

export type WebSearchResultFilters = {
  limit?: number;
  requestBundleId?: string;
  query?: string;
  status?: WebSearchResultRecord['status'];
};

export type OutboxBundleFilters = {
  limit?: number;
  type?: string;
  destinationNodeId?: string;
};

export interface SyncStore {
  saveUploadedBundle(record: UploadedBundleRecord): Promise<void>;
  getUploadedBundle(bundleId: string): Promise<UploadedBundleRecord | undefined>;
  listUploadedBundles(filters?: UploadedBundleFilters): Promise<UploadedBundleRecord[]>;
  hasProcessedBundle(bundleId: string): Promise<boolean>;
  markProcessedBundle(bundleId: string): Promise<void>;

  appendWalletEvent(event: WalletLedgerEvent): Promise<void>;
  listWalletEvents(filters?: string | WalletLedgerFilters): Promise<WalletLedgerEvent[]>;
  findWalletEventBySource(sourceBundleId: string, kind?: WalletLedgerEvent['kind']): Promise<WalletLedgerEvent | undefined>;

  appendOutboxBundle(bundle: Bundle): Promise<void>;
  fetchOutboxBundlesSince(sinceMs: number): Promise<Bundle[]>;
  listOutboxBundles(filters?: OutboxBundleFilters): Promise<Bundle[]>;

  appendAuditEvent(event: AuditEvent): Promise<void>;
  listAuditEvents(filters?: AuditEventFilters): Promise<AuditEvent[]>;

  upsertWebSearchRequest(record: WebSearchRequestRecord): Promise<WebSearchRequestRecord>;
  findWebSearchRequestByDedupe(requesterNodeId: string, normalizedQuery: string): Promise<WebSearchRequestRecord | undefined>;
  listWebSearchRequests(filters?: WebSearchRequestFilters): Promise<WebSearchRequestRecord[]>;
  appendWebSearchResults(results: WebSearchResultRecord[]): Promise<void>;
  listWebSearchResults(filters?: string | WebSearchResultFilters): Promise<WebSearchResultRecord[]>;
}
