import 'dart:convert';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart' as ledger;
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/wallet_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/use_cases/wallet_event_bundle_mapper.dart';

class RewardIssuanceResult {
  const RewardIssuanceResult({
    required this.bundle,
    required this.pendingEntry,
  });

  final Bundle bundle;
  final ledger.WalletLedgerEntry pendingEntry;
}

class RewardIssuanceUseCase {
  RewardIssuanceUseCase({
    required BundleRepository bundleRepository,
    required WalletRepository walletRepository,
    required BundleSignatureService bundleSignatureService,
  }) : _bundleRepository = bundleRepository,
       _walletRepository = walletRepository,
       _bundleSignatureService = bundleSignatureService;

  final BundleRepository _bundleRepository;
  final WalletRepository _walletRepository;
  final BundleSignatureService _bundleSignatureService;

  Future<RewardIssuanceResult> createPendingReward({
    required String localNodeId,
    required int amountMinorUnits,
    required String rewardKind, // 'relay' | 'gateway'
    String? memo,
  }) async {
    final DateTime createdAt = DateTime.now();
    final String bundleId = 'wallet-reward-${createdAt.microsecondsSinceEpoch}';
    final Bundle unsigned = Bundle(
      bundleId: bundleId,
      type: Bundle.typeWalletReward,
      sourceNodeId: localNodeId,
      destinationNodeId: localNodeId,
      destinationScope: BundleDestinationScope.direct,
      payload: jsonEncode(<String, Object?>{
        'kind': 'reward',
        'rewardKind': rewardKind,
        'amountMinorUnits': amountMinorUnits,
        'createdAtMs': createdAt.millisecondsSinceEpoch,
        'memo': memo,
      }),
      appId: WalletEventBundleMapper.walletAppId,
      createdAt: createdAt,
      ttlSeconds: 60 * 60 * 24,
    );

    final Bundle signed = await _bundleSignatureOrSign(unsigned, localNodeId);

    final ledger.WalletLedgerEntry pendingEntry = ledger.WalletLedgerEntry(
      entryId: signed.bundleId,
      kind: rewardKind == 'relay'
          ? ledger.WalletLedgerEventKind.relayReward
          : ledger.WalletLedgerEventKind.gatewayReward,
      title: 'Pending Reward',
      subtitle: rewardKind == 'relay' ? 'Relay Reward' : 'Gateway Reward',
      amountMinorUnits: amountMinorUnits,
      balanceImpactMinorUnits: 0,
      status: ledger.WalletLedgerStatus.pending,
      createdAt: createdAt,
      memo: memo,
      sourceBundleId: signed.bundleId,
    );

    await _bundleRepository.save(signed);
    await _walletRepository.appendEntry(pendingEntry);

    return RewardIssuanceResult(bundle: signed, pendingEntry: pendingEntry);
  }

  // Separated to keep tests easier to mock if needed.
  Future<Bundle> _bundleSignatureOrSign(Bundle unsigned, String nodeId) async {
    return _bundleSignatureOrSignImpl(unsigned, nodeId);
  }

  Future<Bundle> _bundleSignatureOrSignImpl(
    Bundle unsigned,
    String nodeId,
  ) async {
    return _bundleSignatureService.sign(bundle: unsigned, nodeId: nodeId);
  }
}
