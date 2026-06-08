import { describe, expect, it } from 'vitest';
import type { SearchProvider } from '../src/services/webSearchPipeline.js';
import { makeClientIdentity, makeHarness, signedWireBundle, walletSpendBundle } from './helpers.js';

describe('sync API', () => {
  it('confirms a valid spend and exposes confirmation via fetch', async () => {
    const { app } = makeHarness();
    const client = makeClientIdentity(1);
    const spend = walletSpendBundle({ source: client, amountMinorUnits: 1200 });

    const upload = await app.inject({
      method: 'POST',
      url: '/sync/upload',
      payload: { bundles: [spend] }
    });

    expect(upload.statusCode).toBe(200);
    const body = upload.json();
    expect(body.rejections).toEqual([]);
    expect(body).not.toHaveProperty('acknowledgedBundleIds');

    const fetch = await app.inject({ method: 'GET', url: '/sync/fetch?sinceMs=0' });
    const fetched = fetch.json();
    expect(fetched.bundles.some((bundle: { type: string; ackForBundleId: string }) => bundle.type === 'wallet_confirmation' && bundle.ackForBundleId === spend.bundleId)).toBe(true);
  });

  it('rejects an invalid spend without breaking upload shape', async () => {
    const { app } = makeHarness();
    const client = makeClientIdentity(2);
    const spend = walletSpendBundle({ source: client, amountMinorUnits: 999999 });

    const upload = await app.inject({
      method: 'POST',
      url: '/sync/upload',
      payload: { bundles: [spend] }
    });

    expect(upload.statusCode).toBe(200);
    const body = upload.json();
    expect(body.rejections[0]).toMatchObject({
      bundleId: spend.bundleId,
      reason: 'Insufficient server-authoritative balance.'
    });
  });

  it('handles duplicate upload idempotently', async () => {
    const { app } = makeHarness();
    const client = makeClientIdentity(3);
    const spend = walletSpendBundle({ source: client, amountMinorUnits: 500 });

    await app.inject({ method: 'POST', url: '/sync/upload', payload: { bundles: [spend] } });
    const second = await app.inject({ method: 'POST', url: '/sync/upload', payload: { bundles: [spend] } });

    expect(second.json()).not.toHaveProperty('acknowledgedBundleIds');
    const fetch = await app.inject({ method: 'GET', url: '/sync/fetch?sinceMs=0' });
    const confirmations = fetch.json().bundles.filter((bundle: { type: string; ackForBundleId: string }) => bundle.type === 'wallet_confirmation' && bundle.ackForBundleId === spend.bundleId);
    expect(confirmations).toHaveLength(1);
  });

  it('issues relay reward once for ACK evidence', async () => {
    const { app } = makeHarness();
    const relay = makeClientIdentity(4);
    const ack = signedWireBundle(
      {
        bundleId: 'ack-1',
        type: 'ack',
        sourceNodeId: relay.nodeId,
        destinationNodeId: 'node-origin',
        destinationScope: 'direct',
        priority: 'normal',
        ackForBundleId: 'chat-1',
        payload: null,
        payloadReference: null,
        appId: 'offlimu.chat',
        createdAtMs: Date.now(),
        expiresAtMs: null,
        ttlSeconds: 300,
        hopCount: 0,
        acknowledged: false,
        sentAtMs: null,
        failedAttempts: 0,
        lastError: null
      },
      relay
    );

    await app.inject({ method: 'POST', url: '/sync/upload', payload: { bundles: [ack] } });
    await app.inject({ method: 'POST', url: '/sync/upload', payload: { bundles: [ack] } });
    const fetch = await app.inject({ method: 'GET', url: '/sync/fetch?sinceMs=0' });
    const rewards = fetch.json().bundles.filter((bundle: { type: string; ackForBundleId: string }) => bundle.type === 'wallet_reward' && bundle.ackForBundleId?.includes('relay:ack-1'));
    expect(rewards).toHaveLength(1);
  });

  it('returns deterministic web search results for search requests', async () => {
    const { app } = makeHarness();
    const client = makeClientIdentity(5);
    const search = signedWireBundle(
      {
        bundleId: 'web-search-1',
        type: 'web_search_request',
        sourceNodeId: client.nodeId,
        destinationNodeId: null,
        destinationScope: 'broadcast',
        priority: 'high',
        ackForBundleId: null,
        payload: JSON.stringify({ query: 'offline mesh', requestedByNodeId: client.nodeId, maxResults: 2 }),
        payloadReference: null,
        appId: 'offlimu.web',
        createdAtMs: Date.now(),
        expiresAtMs: null,
        ttlSeconds: 86400,
        hopCount: 0,
        acknowledged: false,
        sentAtMs: null,
        failedAttempts: 0,
        lastError: null
      },
      client
    );

    const upload = await app.inject({
      method: 'POST',
      url: '/sync/upload',
      payload: { bundles: [search] }
    });
    const body = upload.json();

    expect(body.webSearchResults).toHaveLength(2);
    expect(body.webSearchResults[0]).toMatchObject({
      requestBundleId: 'web-search-1',
      query: 'offline mesh'
    });
    expect(body.webSearchResults[0].html).toContain('<!doctype html>');
  });

  it('returns scraped and fallback web search snapshots through sync upload', async () => {
    const provider: SearchProvider = {
      name: 'fake-google',
      async search() {
        return [
          {
            title: 'Scraped page',
            url: 'https://example.com/scraped',
            snippet: 'A scrapeable page.',
            rank: 1,
            provider: 'google'
          },
          {
            title: 'Blocked page',
            url: 'https://blocked.example.com/page',
            snippet: 'A blocked page.',
            rank: 2,
            provider: 'google'
          },
          {
            title: 'Plain page',
            url: 'https://plain.example.com/file.txt',
            snippet: 'A non HTML page.',
            rank: 3,
            provider: 'google'
          }
        ];
      }
    };
    const fetchImpl = async (input: URL | RequestInfo) => {
      const url = String(input);
      if (url === 'https://blocked.example.com/robots.txt') {
        return new Response('User-agent: *\nDisallow: /', { status: 200 });
      }
      if (url.endsWith('/robots.txt')) {
        return new Response('', { status: 404 });
      }
      if (url === 'https://plain.example.com/file.txt') {
        return new Response('plain text', {
          status: 200,
          headers: { 'content-type': 'text/plain' }
        });
      }
      return new Response(
        '<html><head><title>Scraped page</title></head><body><main><p>Useful offline content.</p></main></body></html>',
        { status: 200, headers: { 'content-type': 'text/html' } }
      );
    };
    const { app } = makeHarness({
      webSearchOptions: {
        provider: 'google',
        searchProvider: provider,
        maxResults: 3,
        fetchImpl: fetchImpl as typeof fetch
      }
    });
    const client = makeClientIdentity(50);
    const search = signedWireBundle(
      {
        bundleId: 'web-search-scrape-1',
        type: 'web_search_request',
        sourceNodeId: client.nodeId,
        destinationNodeId: null,
        destinationScope: 'broadcast',
        priority: 'high',
        ackForBundleId: null,
        payload: JSON.stringify({ query: 'offline scrape', requestedByNodeId: client.nodeId, maxResults: 3 }),
        payloadReference: null,
        appId: 'offlimu.web',
        createdAtMs: Date.now(),
        expiresAtMs: null,
        ttlSeconds: 86400,
        hopCount: 0,
        acknowledged: false,
        sentAtMs: null,
        failedAttempts: 0,
        lastError: null
      },
      client
    );

    const upload = await app.inject({
      method: 'POST',
      url: '/sync/upload',
      payload: { bundles: [search] }
    });
    const body = upload.json();

    expect(body.webSearchResults).toHaveLength(3);
    expect(body.webSearchResults[0].html).toContain('Useful offline content.');
    expect(body.webSearchResults[1].html).toContain('robots_disallowed');
    expect(body.webSearchResults[2].html).toContain('non_html_content');

    const admin = await app.inject({
      method: 'GET',
      url: '/admin/api/web-searches?query=scrape'
    });
    expect(admin.json()[0]).toMatchObject({ resultCount: 3 });
    expect(admin.json()[0].results.map((result: { error: string | null }) => result.error)).toEqual([
      null,
      'robots_disallowed',
      'non_html_content'
    ]);
  });

  it('fetch respects sinceMs', async () => {
    const { app } = makeHarness();
    const client = makeClientIdentity(6);
    const spend = walletSpendBundle({ source: client, amountMinorUnits: 100 });
    const sinceFuture = Date.now() + 1000;

    await app.inject({ method: 'POST', url: '/sync/upload', payload: { bundles: [spend] } });
    const fetch = await app.inject({ method: 'GET', url: `/sync/fetch?sinceMs=${sinceFuture}` });

    expect(fetch.json().bundles).toEqual([]);
  });
});
