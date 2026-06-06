import { Buffer } from 'node:buffer';
import { sha256Hex } from '../crypto/bundleCrypto.js';
import type { SyncStore, WebSearchResultRecord } from '../db/store.js';
import type { Bundle } from '../types/bundle.js';
import { parseJsonPayload } from '../types/bundle.js';

export type WebSearchResultDto = {
  requestBundleId: string;
  query: string;
  title: string;
  url: string;
  snippet: string;
  html: string;
};

export class WebSearchService {
  constructor(private readonly store: SyncStore) {}

  async processSearchRequest(bundle: Bundle): Promise<WebSearchResultDto[]> {
    const payload = parseJsonPayload(bundle);
    const rawQuery = typeof payload?.query === 'string' ? payload.query.trim() : '';
    if (!rawQuery) return [];

    const requesterNodeId =
      typeof payload?.requestedByNodeId === 'string'
        ? payload.requestedByNodeId
        : bundle.sourceNodeId;
    const normalizedQuery = normalizeQuery(rawQuery);
    const maxResults = clampNumber(Number(payload?.maxResults ?? 3), 1, 5);

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

    const results = buildMockResults({
      requestBundleId: requestRecord.bundleId,
      query: rawQuery,
      maxResults
    });
    await this.store.appendWebSearchResults(results.map(toRecord));
    return results;
  }
}

export function normalizeQuery(value: string): string {
  return value.trim().replace(/\s+/g, ' ').toLowerCase();
}

function clampNumber(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) return min;
  return Math.min(max, Math.max(min, Math.trunc(value)));
}

function buildMockResults(params: {
  requestBundleId: string;
  query: string;
  maxResults: number;
}): WebSearchResultDto[] {
  return Array.from({ length: params.maxResults }, (_, index) => {
    const ordinal = index + 1;
    const title = `Offline result ${ordinal} for ${params.query}`;
    const url = `https://mock.offlimu.local/search/${encodeURIComponent(params.query)}/${ordinal}`;
    const snippet = `A server-generated cached page about "${params.query}".`;
    return {
      requestBundleId: params.requestBundleId,
      query: params.query,
      title,
      url,
      snippet,
      html: mockHtml({ title, url, query: params.query, snippet, ordinal })
    };
  });
}

function mockHtml(params: {
  title: string;
  url: string;
  query: string;
  snippet: string;
  ordinal: number;
}): string {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(params.title)}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 0; color: #1f3524; background: #f6fbf4; }
    main { max-width: 760px; margin: 0 auto; padding: 32px 20px; }
    header { border-bottom: 1px solid #cfe3c8; margin-bottom: 24px; padding-bottom: 20px; }
    .source { color: #53715a; font-size: 14px; word-break: break-all; }
  </style>
</head>
<body>
  <main>
    <header>
      <p class="source">${escapeHtml(params.url)}</p>
      <h1>${escapeHtml(params.title)}</h1>
      <p>${escapeHtml(params.snippet)}</p>
    </header>
    <article>
      <p>This deterministic server snapshot was generated for <strong>${escapeHtml(params.query)}</strong>.</p>
      <p>Result ${params.ordinal} exercises the real OffLiMU sync-server search pipeline while live scraping is deferred.</p>
    </article>
  </main>
</body>
</html>`;
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function toRecord(result: WebSearchResultDto): WebSearchResultRecord {
  return {
    id: sha256Hex(`${result.requestBundleId}:${result.url}`),
    requestBundleId: result.requestBundleId,
    query: result.query,
    title: result.title,
    url: result.url,
    snippet: result.snippet,
    html: result.html,
    contentHash: `sha256:${sha256Hex(result.html)}`,
    byteSize: Buffer.byteLength(result.html, 'utf8'),
    status: 'completed',
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
