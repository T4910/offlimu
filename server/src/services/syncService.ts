import { randomUUID } from 'node:crypto';
import type { Bundle, WireBundle } from '../types/bundle.js';
import { fromWireBundle, isExpired, toWireBundle } from '../types/bundle.js';
import { verifyBundleSignature } from '../crypto/bundleCrypto.js';
import type { SyncStore } from '../db/store.js';
import { RewardService } from './rewardService.js';
import type { WalletProcessResult } from './walletService.js';
import { WalletService } from './walletService.js';
import type { WebSearchResultDto } from './webSearchService.js';
import { WebSearchService } from './webSearchService.js';

export type SyncUploadResult = {
  rejections: Array<{ bundleId: string; reason: string }>;
  webSearchResults: WebSearchResultDto[];
};

export class SyncService {
  constructor(
    private readonly store: SyncStore,
    private readonly wallet: WalletService,
    private readonly rewards: RewardService,
    private readonly webSearch: WebSearchService
  ) {}

  async uploadBundles(wireBundles: WireBundle[]): Promise<SyncUploadResult> {
    const rejections: Array<{ bundleId: string; reason: string }> = [];
    const webSearchResults: WebSearchResultDto[] = [];

    for (const wire of wireBundles) {
      const bundle = fromWireBundle(wire);
      const now = Date.now();
      const signatureValid = verifyBundleSignature(bundle);

      await this.store.saveUploadedBundle({
        bundleId: bundle.bundleId,
        bundle,
        sourceNodeId: bundle.sourceNodeId,
        type: bundle.type,
        signatureValid,
        processingStatus: signatureValid ? 'accepted' : 'rejected',
        firstSeenMs: now,
        lastSeenMs: now
      });

      if (!signatureValid) {
        rejections.push({
          bundleId: bundle.bundleId,
          reason: 'Invalid or missing bundle signature.'
        });
        await this.audit('bundle_rejected_signature', bundle, 'Invalid or missing bundle signature.');
        continue;
      }

      if (isExpired(bundle, now)) {
        rejections.push({ bundleId: bundle.bundleId, reason: 'Bundle expired before sync upload.' });
        await this.audit('bundle_rejected_expired', bundle, 'Bundle expired before sync upload.');
        continue;
      }

      const alreadyProcessed = await this.store.hasProcessedBundle(bundle.bundleId);
      if (alreadyProcessed) {
        if (bundle.type === 'web_search_request') {
          webSearchResults.push(...(await this.webSearch.processSearchRequest(bundle)));
        }
        continue;
      }

      if (bundle.type === 'wallet_spend') {
        const result = await this.wallet.processSpend(bundle);
        this.applyWalletResult(result, rejections);
      } else if (bundle.type === 'ack') {
        await this.rewards.processAck(bundle);
      } else if (bundle.type === 'web_search_request') {
        webSearchResults.push(...(await this.webSearch.processSearchRequest(bundle)));
      }

      await this.rewards.processGatewayUpload(bundle.sourceNodeId, bundle.bundleId);
      await this.store.markProcessedBundle(bundle.bundleId);
      await this.audit('bundle_processed', bundle, `Processed ${bundle.type}.`);
    }

    return { rejections, webSearchResults };
  }

  async fetchRemoteBundles(sinceMs: number): Promise<{ bundles: WireBundle[] }> {
    const bundles = await this.store.fetchOutboxBundlesSince(sinceMs);
    return { bundles: bundles.map(toWireBundle) };
  }

  private applyWalletResult(
    result: WalletProcessResult,
    rejections: Array<{ bundleId: string; reason: string }>
  ): void {
    if (!result.ok) {
      rejections.push({ bundleId: result.rejectedBundleId, reason: result.reason });
    }
  }

  private async audit(kind: string, bundle: Bundle, message: string): Promise<void> {
    await this.store.appendAuditEvent({
      id: randomUUID(),
      kind,
      bundleId: bundle.bundleId,
      nodeId: bundle.sourceNodeId,
      message,
      createdAtMs: Date.now(),
      fields: { type: bundle.type }
    });
  }
}
