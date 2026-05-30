import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart' as ledger;
import 'package:offlimu/domain/repositories/wallet_repository.dart';
import 'package:offlimu/domain/use_cases/wallet_event_bundle_mapper.dart';

class WalletSyncReconciliationService {
  WalletSyncReconciliationService({
    required WalletRepository walletRepository,
    WalletEventBundleMapper? mapper,
    DateTime Function()? now,
  }) : _walletRepository = walletRepository,
       _mapper = mapper ?? const WalletEventBundleMapper(),
       _now = now ?? DateTime.now;

  final WalletRepository _walletRepository;
  final WalletEventBundleMapper _mapper;
  final DateTime Function() _now;

  Future<void> applyUploadResult({
    required List<Bundle> outboundBundles,
    required Set<String> rejectedBundleIds,
    required Map<String, String> rejectedReasonsByBundleId,
  }) async {
    final Map<String, Bundle> bundlesById = <String, Bundle>{
      for (final bundle in outboundBundles) bundle.bundleId: bundle,
    };

    for (final bundleId in rejectedBundleIds) {
      final Bundle? bundle = bundlesById[bundleId];
      if (bundle == null || bundle.type != Bundle.typeWalletSpend) {
        continue;
      }

      final WalletSpendPayload? payload = _mapper.decodeSpendPayload(bundle);
      if (payload == null) {
        continue;
      }

      final String reason = rejectedReasonsByBundleId[bundleId] ??
          'Rejected by sync server';
      await _walletRepository.appendEntry(
        ledger.WalletLedgerEntry(
          entryId: 'wallet-spend-rejected-$bundleId',
          kind: ledger.WalletLedgerEventKind.rejection,
          title: 'Rejected Spend',
          subtitle: reason,
          amountMinorUnits: -payload.amountMinorUnits,
          balanceImpactMinorUnits: 0,
          status: ledger.WalletLedgerStatus.rejected,
          createdAt: _now(),
          memo: payload.memo ?? reason,
          counterpartyNodeId: payload.recipientNodeId,
          sourceBundleId: bundleId,
        ),
      );
    }
  }

  Future<void> applyInboundWalletBundle(Bundle bundle) async {
    if (bundle.type == Bundle.typeWalletConfirmation) {
      await _applyConfirmation(bundle);
      return;
    }

    if (bundle.type == Bundle.typeWalletRejection) {
      await _applyRejection(bundle);
      return;
    }

    if (bundle.type == Bundle.typeWalletReward) {
      await _applyReward(bundle);
      return;
    }
  }

  Future<void> _applyReward(Bundle bundle) async {
    final WalletRewardPayload? payload = _mapper.decodeRewardPayload(bundle);
    if (payload == null) {
      return;
    }

    final kind = payload.rewardKind == 'relay'
        ? ledger.WalletLedgerEventKind.relayReward
        : ledger.WalletLedgerEventKind.gatewayReward;

    await _walletRepository.appendEntry(
      ledger.WalletLedgerEntry(
        entryId: 'wallet-reward-${bundle.bundleId}',
        kind: kind,
        title: 'Reward',
        subtitle: payload.rewardKind == 'relay' ? 'Relay reward' : 'Gateway reward',
        amountMinorUnits: payload.amountMinorUnits,
        balanceImpactMinorUnits: payload.amountMinorUnits,
        status: ledger.WalletLedgerStatus.confirmed,
        createdAt: payload.createdAt,
        memo: payload.memo,
        sourceBundleId: payload.sourceBundleId ?? bundle.bundleId,
      ),
    );
  }

  Future<void> _applyConfirmation(Bundle bundle) async {
    final WalletReconciliationPayload? payload =
        _mapper.decodeReconciliationPayload(bundle);
    if (payload == null) {
      return;
    }

    await _walletRepository.appendEntry(
      ledger.WalletLedgerEntry(
        entryId: 'wallet-spend-confirmed-${payload.sourceSpendBundleId}',
        kind: ledger.WalletLedgerEventKind.spend,
        title: 'Settled Spend',
        subtitle: 'To ${payload.recipientNodeId}',
        amountMinorUnits: -payload.amountMinorUnits,
        balanceImpactMinorUnits: -payload.amountMinorUnits,
        status: ledger.WalletLedgerStatus.confirmed,
        createdAt: payload.createdAt,
        memo: payload.memo,
        counterpartyNodeId: payload.recipientNodeId,
        sourceBundleId: payload.sourceSpendBundleId,
      ),
    );
  }

  Future<void> _applyRejection(Bundle bundle) async {
    final WalletReconciliationPayload? payload =
        _mapper.decodeReconciliationPayload(bundle);
    if (payload == null) {
      return;
    }

    final String reason = payload.reason ?? 'Rejected by sync server';
    await _walletRepository.appendEntry(
      ledger.WalletLedgerEntry(
        entryId: 'wallet-spend-rejected-${payload.sourceSpendBundleId}',
        kind: ledger.WalletLedgerEventKind.rejection,
        title: 'Rejected Spend',
        subtitle: reason,
        amountMinorUnits: -payload.amountMinorUnits,
        balanceImpactMinorUnits: 0,
        status: ledger.WalletLedgerStatus.rejected,
        createdAt: payload.createdAt,
        memo: payload.memo ?? reason,
        counterpartyNodeId: payload.recipientNodeId,
        sourceBundleId: payload.sourceSpendBundleId,
      ),
    );
  }
}
