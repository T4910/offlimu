import nacl from 'tweetnacl';
import { createServerIdentity, signBundle, type ServerIdentity } from '../src/crypto/bundleCrypto.js';
import { MemorySyncStore } from '../src/db/memoryStore.js';
import { buildApp } from '../src/http/app.js';
import { RewardService } from '../src/services/rewardService.js';
import { SyncService } from '../src/services/syncService.js';
import { WalletService } from '../src/services/walletService.js';
import { WebSearchService } from '../src/services/webSearchService.js';
import type { Bundle, WireBundle } from '../src/types/bundle.js';
import { toWireBundle } from '../src/types/bundle.js';

export function makeHarness() {
  const store = new MemorySyncStore();
  const identity = createServerIdentity({ nodeId: 'server-gateway' });
  const wallet = new WalletService(store, identity, 5000);
  const rewards = new RewardService(wallet);
  const webSearch = new WebSearchService(store);
  const sync = new SyncService(store, wallet, rewards, webSearch);
  const app = buildApp(sync);
  return { store, identity, wallet, rewards, webSearch, sync, app };
}

export function makeClientIdentity(seedByte = 1): ServerIdentity {
  const seed = Buffer.alloc(32, seedByte);
  const keyPair = nacl.sign.keyPair.fromSeed(seed);
  return {
    nodeId: `node-${seedByte}`,
    publicKeyBase64: Buffer.from(keyPair.publicKey).toString('base64'),
    seedBase64: seed.toString('base64')
  };
}

export function signedWireBundle(bundle: Omit<Bundle, 'sourcePublicKey' | 'signature'>, identity: ServerIdentity): WireBundle {
  return toWireBundle(signBundle({ ...bundle, sourcePublicKey: null, signature: null }, identity));
}

export function walletSpendBundle(params: {
  source: ServerIdentity;
  recipientNodeId?: string;
  amountMinorUnits?: number;
  bundleId?: string;
  createdAtMs?: number;
}): WireBundle {
  const createdAtMs = params.createdAtMs ?? Date.now();
  const recipientNodeId = params.recipientNodeId ?? 'node-recipient';
  const amountMinorUnits = params.amountMinorUnits ?? 1000;
  return signedWireBundle(
    {
      bundleId: params.bundleId ?? `wallet-spend-${createdAtMs}`,
      type: 'wallet_spend',
      sourceNodeId: params.source.nodeId,
      destinationNodeId: recipientNodeId,
      destinationScope: 'direct',
      priority: 'normal',
      ackForBundleId: null,
      payload: JSON.stringify({
        kind: 'spend',
        recipientNodeId,
        amountMinorUnits,
        memo: 'test spend',
        createdAtMs
      }),
      payloadReference: null,
      appId: 'offlimu.wallet',
      createdAtMs,
      expiresAtMs: null,
      ttlSeconds: 3600,
      hopCount: 0,
      acknowledged: false,
      sentAtMs: null,
      failedAttempts: 0,
      lastError: null
    },
    params.source
  );
}
