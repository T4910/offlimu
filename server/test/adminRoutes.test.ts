import { describe, expect, it } from 'vitest';
import { makeClientIdentity, makeHarness, signedWireBundle, walletSpendBundle } from './helpers.js';

describe('admin console', () => {
  it('returns summary metrics from uploaded sync activity', async () => {
    const { app } = makeHarness();
    const client = makeClientIdentity(20);
    const spend = walletSpendBundle({ source: client, amountMinorUnits: 300 });

    await app.inject({
      method: 'POST',
      url: '/sync/upload',
      payload: { bundles: [spend] }
    });

    const response = await app.inject({ method: 'GET', url: '/admin/api/summary' });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      metrics: {
        totalUploads: 1,
        rejectedUploads: 0,
        activeNodes: 2
      }
    });
  });

  it('serves admin HTML pages', async () => {
    const { app } = makeHarness();
    const pages = [
      ['/admin', 'OffLiMU Admin'],
      ['/admin/ledger', 'Main Ledger'],
      ['/admin/web-searches', 'Circulating Web Searches'],
      ['/admin/bundles', 'Uploaded Bundles'],
      ['/admin/outbox', 'Server Outbox'],
      ['/admin/audit', 'Audit Logs']
    ];

    for (const [url, marker] of pages) {
      const response = await app.inject({ method: 'GET', url });
      expect(response.statusCode).toBe(200);
      expect(response.headers['content-type']).toContain('text/html');
      expect(response.body).toContain(marker);
    }
  });

  it('filters ledger and uploaded bundle admin APIs', async () => {
    const { app } = makeHarness();
    const client = makeClientIdentity(21);
    const spend = walletSpendBundle({ source: client, amountMinorUnits: 200 });

    await app.inject({
      method: 'POST',
      url: '/sync/upload',
      payload: { bundles: [spend] }
    });

    const ledger = await app.inject({
      method: 'GET',
      url: `/admin/api/ledger?nodeId=${client.nodeId}&kind=spend`
    });
    expect(ledger.json()).toEqual([
      expect.objectContaining({ nodeId: client.nodeId, kind: 'spend' })
    ]);

    const bundles = await app.inject({
      method: 'GET',
      url: '/admin/api/bundles?type=wallet_spend&status=accepted'
    });
    expect(bundles.json()).toEqual([
      expect.objectContaining({ bundleId: spend.bundleId, type: 'wallet_spend' })
    ]);
  });

  it('filters web search requests and exposes result metadata', async () => {
    const { app } = makeHarness();
    const client = makeClientIdentity(22);
    const search = signedWireBundle(
      {
        bundleId: 'admin-web-search-1',
        type: 'web_search_request',
        sourceNodeId: client.nodeId,
        destinationNodeId: null,
        destinationScope: 'broadcast',
        priority: 'high',
        ackForBundleId: null,
        payload: JSON.stringify({
          query: 'offline market',
          requestedByNodeId: client.nodeId,
          maxResults: 2
        }),
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

    await app.inject({
      method: 'POST',
      url: '/sync/upload',
      payload: { bundles: [search] }
    });

    const response = await app.inject({
      method: 'GET',
      url: '/admin/api/web-searches?query=market'
    });
    const body = response.json();
    expect(body).toHaveLength(1);
    expect(body[0]).toMatchObject({
      bundleId: 'admin-web-search-1',
      query: 'offline market',
      resultCount: 2
    });
    expect(body[0].results[0].contentHash).toContain('sha256:');
  });
});
