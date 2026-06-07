import { Buffer } from 'node:buffer';
import { randomUUID } from 'node:crypto';
import { sha256Hex } from '../crypto/bundleCrypto.js';
import type { SyncStore, WebSearchResultRecord } from '../db/store.js';
import type { Bundle } from '../types/bundle.js';
import { parseJsonPayload } from '../types/bundle.js';
import {
  createSearchProvider,
  createSnapshotter,
  MockSearchProvider,
  type SearchProvider,
  type SnapshotResult,
  type WebSearchPipelineOptions
} from './webSearchPipeline.js';

export type WebSearchResultDto = {
  requestBundleId: string;
  query: string;
  title: string;
  url: string;
  snippet: string;
  html: string;
};

export type WebSearchServiceOptions = Partial<WebSearchPipelineOptions> & {
  searchProvider?: SearchProvider;
};

const defaultPipelineOptions: WebSearchPipelineOptions = {
  provider: 'mock',
  maxResults: 3,
  scrapeTimeoutMs: 8000,
  scrapeMaxBytes: 1_000_000,
  scraperUserAgent: 'OffLiMU-SyncServer/0.1 (+https://offlimu.local)',
};

export class WebSearchService {
  private readonly options: WebSearchPipelineOptions;
  private readonly searchProvider: SearchProvider;

  constructor(
    private readonly store: SyncStore,
    options: WebSearchServiceOptions = {}
  ) {
    this.options = {
      ...defaultPipelineOptions,
      ...options,
      provider: options.provider ?? defaultPipelineOptions.provider,
      maxResults: clampNumber(
        Number(options.maxResults ?? defaultPipelineOptions.maxResults),
        1,
        5
      ),
      scrapeTimeoutMs: clampNumber(
        Number(options.scrapeTimeoutMs ?? defaultPipelineOptions.scrapeTimeoutMs),
        1000,
        60000
      ),
      scrapeMaxBytes: clampNumber(
        Number(options.scrapeMaxBytes ?? defaultPipelineOptions.scrapeMaxBytes),
        10000,
        5_000_000
      )
    };
    this.searchProvider =
      options.searchProvider ?? createSearchProvider(this.options);
  }

  async processSearchRequest(bundle: Bundle): Promise<WebSearchResultDto[]> {
    const payload = parseJsonPayload(bundle);
    const rawQuery = typeof payload?.query === 'string' ? payload.query.trim() : '';
    if (!rawQuery) return [];

    const requesterNodeId =
      typeof payload?.requestedByNodeId === 'string'
        ? payload.requestedByNodeId
        : bundle.sourceNodeId;
    const normalizedQuery = normalizeQuery(rawQuery);
    const requestedMaxResults = clampNumber(Number(payload?.maxResults ?? this.options.maxResults), 1, 5);
    const maxResults = Math.min(requestedMaxResults, this.options.maxResults);

    const existing = await this.store.findWebSearchRequestByDedupe(requesterNodeId, normalizedQuery);
    const requestRecord = await this.store.upsertWebSearchRequest({
      bundleId: existing?.bundleId ?? bundle.bundleId,
      requesterNodeId,
      query: rawQuery,
      normalizedQuery,
      maxResults,
      status: 'completed',
      createdAtMs: bundle.createdAtMs
    });

    const existingResults = await this.store.listWebSearchResults(requestRecord.bundleId);
    if (existingResults.length > 0) {
      return existingResults.map(toDto);
    }

    const candidates = await this.searchCandidates({
      query: rawQuery,
      maxResults,
      bundle
    });
    const snapshotter = createSnapshotter(this.options);
    const snapshots: SnapshotResult[] = [];

    for (const candidate of candidates.slice(0, maxResults)) {
      const snapshot = await snapshotter.snapshot({
        query: rawQuery,
        candidate
      });
      snapshots.push(snapshot);
      await this.audit(
        snapshot.error ? 'web_page_fallback_generated' : 'web_page_scraped',
        bundle,
        snapshot.error
          ? `Generated fallback snapshot for ${candidate.url}: ${snapshot.error}.`
          : `Scraped ${candidate.url}.`,
        {
          url: candidate.url,
          provider: candidate.provider,
          rank: candidate.rank,
          error: snapshot.error ?? null
        }
      );
    }

    const records = snapshots.map((snapshot) =>
      toRecord({
        requestBundleId: requestRecord.bundleId,
        query: rawQuery,
        snapshot
      })
    );
    await this.store.appendWebSearchResults(records);
    return records.map(toDto);
  }

  private async searchCandidates(params: {
    query: string;
    maxResults: number;
    bundle: Bundle;
  }) {
    try {
      const candidates = await this.searchProvider.search({
        query: params.query,
        maxResults: params.maxResults
      });
      await this.audit(
        'web_search_provider_used',
        params.bundle,
        `Used ${this.searchProvider.name} search provider.`,
        { provider: this.searchProvider.name, candidateCount: candidates.length }
      );
      return candidates;
    } catch (error) {
      await this.audit(
        'web_search_provider_failed',
        params.bundle,
        `${this.searchProvider.name} search provider failed; using mock fallback.`,
        {
          provider: this.searchProvider.name,
          error: error instanceof Error ? error.message : String(error)
        }
      );
      return new MockSearchProvider().search({
        query: params.query,
        maxResults: params.maxResults
      });
    }
  }

  private async audit(
    kind: string,
    bundle: Bundle,
    message: string,
    fields?: Record<string, unknown>
  ): Promise<void> {
    await this.store.appendAuditEvent({
      id: randomUUID(),
      kind,
      bundleId: bundle.bundleId,
      nodeId: bundle.sourceNodeId,
      message,
      createdAtMs: Date.now(),
      fields
    });
  }
}

export function createWebSearchServiceFromEnv(
  store: SyncStore,
  env: {
    WEB_SEARCH_PROVIDER?: 'google' | 'mock';
    GOOGLE_CSE_API_KEY?: string;
    GOOGLE_CSE_ID?: string;
    WEB_SEARCH_MAX_RESULTS?: number;
    WEB_SCRAPE_TIMEOUT_MS?: number;
    WEB_SCRAPE_MAX_BYTES?: number;
    WEB_SCRAPER_USER_AGENT?: string;
  }
): WebSearchService {
  const hasGoogleConfig = Boolean(env.GOOGLE_CSE_API_KEY && env.GOOGLE_CSE_ID);
  return new WebSearchService(store, {
    provider: env.WEB_SEARCH_PROVIDER === 'google' && hasGoogleConfig ? 'google' : 'mock',
    googleApiKey: env.GOOGLE_CSE_API_KEY,
    googleCseId: env.GOOGLE_CSE_ID,
    maxResults: env.WEB_SEARCH_MAX_RESULTS,
    scrapeTimeoutMs: env.WEB_SCRAPE_TIMEOUT_MS,
    scrapeMaxBytes: env.WEB_SCRAPE_MAX_BYTES,
    scraperUserAgent: env.WEB_SCRAPER_USER_AGENT
  });
}

export function normalizeQuery(value: string): string {
  return value.trim().replace(/\s+/g, ' ').toLowerCase();
}

function clampNumber(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) return min;
  return Math.min(max, Math.max(min, Math.trunc(value)));
}

function toRecord(params: {
  requestBundleId: string;
  query: string;
  snapshot: SnapshotResult;
}): WebSearchResultRecord {
  return {
    id: sha256Hex(`${params.requestBundleId}:${params.snapshot.url}`),
    requestBundleId: params.requestBundleId,
    query: params.query,
    title: params.snapshot.title,
    url: params.snapshot.url,
    snippet: params.snapshot.snippet,
    html: params.snapshot.html,
    contentHash: `sha256:${sha256Hex(params.snapshot.html)}`,
    byteSize: Buffer.byteLength(params.snapshot.html, 'utf8'),
    status: params.snapshot.error ? 'failed' : 'completed',
    error: params.snapshot.error ?? null,
    createdAtMs: Date.now()
  };
}

function toDto(record: WebSearchResultRecord): WebSearchResultDto {
  return {
    requestBundleId: record.requestBundleId,
    query: record.query,
    title: record.title,
    url: record.url,
    snippet: record.snippet,
    html: record.html
  };
}
