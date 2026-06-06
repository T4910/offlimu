import type { ServerIdentity } from '../crypto/bundleCrypto.js';
import { signBundle } from '../crypto/bundleCrypto.js';
import type { SyncStore, WalletLedgerEvent } from '../db/store.js';
import type { Bundle } from '../types/bundle.js';
import { isExpired, parseJsonPayload } from '../types/bundle.js';

export type WalletProcessResult =
  | { ok: true; acknowledgedBundleId: string; generatedBundles: Bundle[] }
  | { ok: false; rejectedBundleId: string; reason: string; generatedBundles: Bundle[] };

export class WalletService {
  constructor(
    private readonly store: SyncStore,
    private readonly identity: ServerIdentity,
    private readonly openingGrantMinorUnits: number
  ) {}

  async processSpend(bundle: Bundle): Promise<WalletProcessResult> {
    const existingDecision =
      (await this.store.findWalletEventBySource(bundle.bundleId, 'confirmation')) ??
      (await this.store.findWalletEventBySource(bundle.bundleId, 'rejection'));
    if (existingDecision) {
      return { ok: true, acknowledgedBundleId: bundle.bundleId, generatedBundles: [] };
    }

    const payload = decodeSpendPayload(bundle);
    if (!payload) {
      return this.reject(bundle, 'Malformed wallet spend payload.');
    }
    if (payload.amountMinorUnits <= 0) {
      return this.reject(bundle, 'Spend amount must be positive.');
    }
    if (payload.recipientNodeId !== bundle.destinationNodeId) {
      return this.reject(bundle, 'Spend recipient does not match destination.');
    }
    if (isExpired(bundle)) {
      return this.reject(bundle, 'Spend bundle expired before reconciliation.');
    }

    await this.ensureOpeningGrant(bundle.sourceNodeId, bundle.createdAtMs);
    const balance = await this.balanceFor(bundle.sourceNodeId);
    if (balance < payload.amountMinorUnits) {
      return this.reject(bundle, 'Insufficient server-authoritative balance.');
    }

    await this.store.appendWalletEvent({
      eventId: `wallet-spend-confirmed-${bundle.bundleId}`,
      nodeId: bundle.sourceNodeId,
      counterpartyNodeId: payload.recipientNodeId,
      kind: 'spend',
      amountMinorUnits: -payload.amountMinorUnits,
      balanceImpactMinorUnits: -payload.amountMinorUnits,
      status: 'confirmed',
      sourceBundleId: bundle.bundleId,
      memo: payload.memo ?? null,
      createdAtMs: Date.now()
    });
    await this.store.appendWalletEvent({
      eventId: `wallet-received-${bundle.bundleId}`,
      nodeId: payload.recipientNodeId,
      counterpartyNodeId: bundle.sourceNodeId,
      kind: 'confirmation',
      amountMinorUnits: payload.amountMinorUnits,
      balanceImpactMinorUnits: payload.amountMinorUnits,
      status: 'confirmed',
      sourceBundleId: bundle.bundleId,
      memo: payload.memo ?? null,
      createdAtMs: Date.now()
    });

    const confirmation = this.signReconciliationBundle({
      type: 'wallet_confirmation',
      sourceSpendBundleId: bundle.bundleId,
      recipientNodeId: payload.recipientNodeId,
      amountMinorUnits: payload.amountMinorUnits,
      memo: payload.memo ?? null,
      createdAtMs: Date.now()
    });
    await this.store.appendOutboxBundle(confirmation);
    return {
      ok: true,
      acknowledgedBundleId: bundle.bundleId,
      generatedBundles: [confirmation]
    };
  }

  async issueReward(params: {
    rewardKind: 'relay' | 'gateway';
    nodeId: string;
    amountMinorUnits: number;
    sourceBundleId: string;
    memo: string;
  }): Promise<Bundle | undefined> {
    const kind = params.rewardKind === 'relay' ? 'relay_reward' : 'gateway_reward';
    const existing = await this.store.findWalletEventBySource(params.sourceBundleId, kind);
    if (existing) return undefined;

    const now = Date.now();
    await this.store.appendWalletEvent({
      eventId: `wallet-reward-${params.rewardKind}-${params.sourceBundleId}`,
      nodeId: params.nodeId,
      kind,
      amountMinorUnits: params.amountMinorUnits,
      balanceImpactMinorUnits: params.amountMinorUnits,
      status: 'confirmed',
      sourceBundleId: params.sourceBundleId,
      memo: params.memo,
      createdAtMs: now
    });

    const rewardBundle = signBundle(
      {
        bundleId: `wallet-reward-${params.rewardKind}-${params.sourceBundleId}`,
        type: 'wallet_reward',
        sourceNodeId: this.identity.nodeId,
        destinationNodeId: params.nodeId,
        destinationScope: 'direct',
        priority: 'normal',
        ackForBundleId: params.sourceBundleId,
        payload: JSON.stringify({
          kind: 'reward',
          amountMinorUnits: params.amountMinorUnits,
          rewardKind: params.rewardKind,
          sourceBundleId: params.sourceBundleId,
          memo: params.memo,
          createdAtMs: now
        }),
        payloadReference: null,
        appId: 'offlimu.wallet',
        createdAtMs: now,
        expiresAtMs: null,
        ttlSeconds: 3600,
        hopCount: 0,
        acknowledged: true,
        sentAtMs: null,
        failedAttempts: 0,
        lastError: null
      },
      this.identity
    );
    await this.store.appendOutboxBundle(rewardBundle);
    return rewardBundle;
  }

  private async reject(bundle: Bundle, reason: string): Promise<WalletProcessResult> {
    const payload = decodeSpendPayload(bundle);
    const now = Date.now();
    if (payload) {
      await this.store.appendWalletEvent({
        eventId: `wallet-spend-rejected-${bundle.bundleId}`,
        nodeId: bundle.sourceNodeId,
        counterpartyNodeId: payload.recipientNodeId,
        kind: 'rejection',
        amountMinorUnits: -payload.amountMinorUnits,
        balanceImpactMinorUnits: 0,
        status: 'rejected',
        sourceBundleId: bundle.bundleId,
        memo: reason,
        createdAtMs: now
      });
    }
    const rejection = this.signReconciliationBundle({
      type: 'wallet_rejection',
      sourceSpendBundleId: bundle.bundleId,
      recipientNodeId: payload?.recipientNodeId ?? bundle.destinationNodeId ?? bundle.sourceNodeId,
      amountMinorUnits: payload?.amountMinorUnits ?? 0,
      memo: payload?.memo ?? null,
      reason,
      createdAtMs: now
    });
    await this.store.appendOutboxBundle(rejection);
    return {
      ok: false,
      rejectedBundleId: bundle.bundleId,
      reason,
      generatedBundles: [rejection]
    };
  }

  private signReconciliationBundle(params: {
    type: 'wallet_confirmation' | 'wallet_rejection';
    sourceSpendBundleId: string;
    recipientNodeId: string;
    amountMinorUnits: number;
    memo?: string | null;
    reason?: string;
    createdAtMs: number;
  }): Bundle {
    return signBundle(
      {
        bundleId: `${params.type}-${params.sourceSpendBundleId}`,
        type: params.type,
        sourceNodeId: this.identity.nodeId,
        destinationNodeId: params.recipientNodeId,
        destinationScope: 'direct',
        priority: 'normal',
        ackForBundleId: params.sourceSpendBundleId,
        payload: JSON.stringify({
          kind: params.type === 'wallet_confirmation' ? 'confirmation' : 'rejection',
          sourceSpendBundleId: params.sourceSpendBundleId,
          recipientNodeId: params.recipientNodeId,
          amountMinorUnits: params.amountMinorUnits,
          memo: params.memo ?? null,
          reason: params.reason,
          createdAtMs: params.createdAtMs
        }),
        payloadReference: null,
        appId: 'offlimu.wallet',
        createdAtMs: params.createdAtMs,
        expiresAtMs: null,
        ttlSeconds: 3600,
        hopCount: 0,
        acknowledged: true,
        sentAtMs: null,
        failedAttempts: 0,
        lastError: null
      },
      this.identity
    );
  }

  private async ensureOpeningGrant(nodeId: string, createdAtMs: number): Promise<void> {
    const existing = await this.store.findWalletEventBySource(`opening-grant:${nodeId}`, 'opening_grant');
    if (existing) return;
    await this.store.appendWalletEvent({
      eventId: `opening-grant-${nodeId}`,
      nodeId,
      kind: 'opening_grant',
      amountMinorUnits: this.openingGrantMinorUnits,
      balanceImpactMinorUnits: this.openingGrantMinorUnits,
      status: 'confirmed',
      sourceBundleId: `opening-grant:${nodeId}`,
      memo: 'Initial OffLiMU server grant',
      createdAtMs
    });
  }

  private async balanceFor(nodeId: string): Promise<number> {
    const events = await this.store.listWalletEvents(nodeId);
    return events.reduce((sum, event) => sum + event.balanceImpactMinorUnits, 0);
  }
}

export type WalletSpendPayload = {
  recipientNodeId: string;
  amountMinorUnits: number;
  memo?: string | null;
  createdAtMs: number;
};

export function decodeSpendPayload(bundle: Bundle): WalletSpendPayload | null {
  const payload = parseJsonPayload(bundle);
  if (!payload || payload.kind !== 'spend') return null;
  const amountMinorUnits = Number(payload.amountMinorUnits);
  const recipientNodeId = typeof payload.recipientNodeId === 'string' ? payload.recipientNodeId : null;
  const createdAtMs = Number(payload.createdAtMs);
  if (!recipientNodeId || !Number.isInteger(amountMinorUnits) || !Number.isInteger(createdAtMs)) {
    return null;
  }
  return {
    recipientNodeId,
    amountMinorUnits,
    memo: typeof payload.memo === 'string' ? payload.memo : null,
    createdAtMs
  };
}
