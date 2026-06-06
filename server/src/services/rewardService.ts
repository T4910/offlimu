import type { Bundle } from '../types/bundle.js';
import { WalletService } from './walletService.js';

export class RewardService {
  constructor(private readonly wallet: WalletService) {}

  async processAck(bundle: Bundle): Promise<void> {
    if (bundle.type !== 'ack' || !bundle.ackForBundleId) return;
    await this.wallet.issueReward({
      rewardKind: 'relay',
      nodeId: bundle.sourceNodeId,
      amountMinorUnits: 25,
      sourceBundleId: `relay:${bundle.bundleId}:${bundle.ackForBundleId}`,
      memo: `Relay proof for ${bundle.ackForBundleId}`
    });
  }

  async processGatewayUpload(sourceNodeId: string, sourceBundleId: string): Promise<void> {
    await this.wallet.issueReward({
      rewardKind: 'gateway',
      nodeId: sourceNodeId,
      amountMinorUnits: 10,
      sourceBundleId: `gateway:${sourceBundleId}`,
      memo: `Gateway upload accepted for ${sourceBundleId}`
    });
  }
}
