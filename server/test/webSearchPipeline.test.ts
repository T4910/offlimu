import { describe, expect, it, vi } from 'vitest';
import { MemorySyncStore } from '../src/db/memoryStore.js';
import type { Bundle } from '../src/types/bundle.js';
import {
  GoogleSearchProvider,
  PageSnapshotter,
  type SearchCandidate,
  type SearchProvider
} from '../src/services/webSearchPipeline.js';
import { WebSearchService } from '../src/services/webSearchService.js';

describe('web search pipeline', () => {
  it('maps Google Custom Search JSON results into candidates', async () => {
    const fetchImpl = vi.fn(async () =>
      new Response(
        JSON.stringify({
          items: [
            {
              title: 'Mesh Networking',
              link: 'https://example.com/mesh',
              snippet: 'A page about mesh networking.'
            }
          ]
        }),
        { status: 200, headers: { 'content-type': 'application/json' } }
      )
    );
    const provider = new GoogleSearchProvider({
      apiKey: 'key',
      cseId: 'cx',
      fetchImpl: fetchImpl as typeof fetch
    });

    const results = await provider.search({
      query: 'mesh',
      maxResults: 3
    });

    expect(results).toEqual([
      {
        title: 'Mesh Networking',
        url: 'https://example.com/mesh',
        snippet: 'A page about mesh networking.',
        rank: 1,
        provider: 'google'
      }
    ]);
    const firstCall = fetchImpl.mock.calls[0] as unknown[] | undefined;
    expect(String(firstCall?.[0])).toContain(
      'www.googleapis.com/customsearch/v1'
    );
  });

  it('returns a fallback snapshot when robots.txt disallows a page', async () => {
    const snapshotter = new PageSnapshotter({
      timeoutMs: 1000,
      maxBytes: 100000,
      userAgent: 'OffLiMU-TestBot',
      fetchImpl: vi.fn(async (input: URL | RequestInfo) => {
        const url = String(input);
        if (url.endsWith('/robots.txt')) {
          return new Response('User-agent: *\nDisallow: /blocked', {
            status: 200
          });
        }
        return new Response('<html><body>blocked</body></html>', {
          status: 200,
          headers: { 'content-type': 'text/html' }
        });
      }) as typeof fetch
    });

    const snapshot = await snapshotter.snapshot({
      query: 'mesh',
      candidate: candidate('https://example.com/blocked/page')
    });

    expect(snapshot.error).toBe('robots_disallowed');
    expect(snapshot.html).toContain('Reason:</strong> robots_disallowed');
  });

  it('returns fallback snapshots for non-html and oversized pages', async () => {
    const nonHtml = new PageSnapshotter({
      timeoutMs: 1000,
      maxBytes: 100000,
      userAgent: 'OffLiMU-TestBot',
      fetchImpl: vi.fn(async (input: URL | RequestInfo) => {
        const url = String(input);
        if (url.endsWith('/robots.txt')) return new Response('', { status: 404 });
        return new Response('plain text', {
          status: 200,
          headers: { 'content-type': 'text/plain' }
        });
      }) as typeof fetch
    });
    const oversized = new PageSnapshotter({
      timeoutMs: 1000,
      maxBytes: 10,
      userAgent: 'OffLiMU-TestBot',
      fetchImpl: vi.fn(async (input: URL | RequestInfo) => {
        const url = String(input);
        if (url.endsWith('/robots.txt')) return new Response('', { status: 404 });
        return new Response('<html><body>this is too large</body></html>', {
          status: 200,
          headers: { 'content-type': 'text/html' }
        });
      }) as typeof fetch
    });

    expect(
      (
        await nonHtml.snapshot({
          query: 'mesh',
          candidate: candidate('https://example.com/file.txt')
        })
      ).error
    ).toBe('non_html_content');
    expect(
      (
        await oversized.snapshot({
          query: 'mesh',
          candidate: candidate('https://example.com/large')
        })
      ).error
    ).toBe('oversized_page');
  });

  it('sanitizes successful HTML snapshots', async () => {
    const snapshotter = new PageSnapshotter({
      timeoutMs: 1000,
      maxBytes: 100000,
      userAgent: 'OffLiMU-TestBot',
      fetchImpl: vi.fn(async (input: URL | RequestInfo) => {
        const url = String(input);
        if (url.endsWith('/robots.txt')) return new Response('', { status: 404 });
        return new Response(
          '<html><head><title>Clean Page</title><script>alert(1)</script></head><body><main><h1>Hello</h1><p>Readable content.</p><script>alert(2)</script></main></body></html>',
          { status: 200, headers: { 'content-type': 'text/html' } }
        );
      }) as typeof fetch
    });

    const snapshot = await snapshotter.snapshot({
      query: 'mesh',
      candidate: candidate('https://example.com/page')
    });

    expect(snapshot.error).toBeUndefined();
    expect(snapshot.title).toBe('Clean Page');
    expect(snapshot.html).toContain('Readable content.');
    expect(snapshot.html).not.toContain('<script');
  });

  it('does not search or scrape duplicate stored requests', async () => {
    const store = new MemorySyncStore();
    const provider: SearchProvider = {
      name: 'fake-google',
      search: vi.fn(async () => [
        candidate('https://example.com/page')
      ])
    };
    const fetchImpl = vi.fn(async (input: URL | RequestInfo) => {
      const url = String(input);
      if (url.endsWith('/robots.txt')) return new Response('', { status: 404 });
      return new Response('<html><body><main><p>Cached once.</p></main></body></html>', {
        status: 200,
        headers: { 'content-type': 'text/html' }
      });
    });
    const service = new WebSearchService(store, {
      provider: 'google',
      searchProvider: provider,
      fetchImpl: fetchImpl as typeof fetch
    });
    const bundle = searchBundle('web-search-duplicate');

    await service.processSearchRequest(bundle);
    await service.processSearchRequest(bundle);

    expect(provider.search).toHaveBeenCalledTimes(1);
    expect(fetchImpl).toHaveBeenCalledTimes(2);
  });
});

function candidate(url: string): SearchCandidate {
  return {
    title: 'Result',
    url,
    snippet: 'Snippet',
    rank: 1,
    provider: 'google'
  };
}

function searchBundle(bundleId: string): Bundle {
  const createdAtMs = Date.now();
  return {
    bundleId,
    type: 'web_search_request',
    sourceNodeId: 'node-a',
    sourcePublicKey: null,
    destinationNodeId: null,
    destinationScope: 'broadcast',
    priority: 'high',
    ackForBundleId: null,
    payload: JSON.stringify({
      query: 'mesh',
      requestedByNodeId: 'node-a',
      maxResults: 1
    }),
    payloadReference: null,
    signature: null,
    appId: 'offlimu.web',
    createdAtMs,
    expiresAtMs: null,
    ttlSeconds: 86400,
    hopCount: 0,
    acknowledged: false,
    sentAtMs: null,
    failedAttempts: 0,
    lastError: null
  };
}
