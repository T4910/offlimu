import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart' as ledger;
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/wallet_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/use_cases/wallet_event_bundle_mapper.dart';

class WalletSpendDispatchResult {
  const WalletSpendDispatchResult({
    required this.bundle,
    required this.pendingEntry,
  });

  final Bundle bundle;
  final ledger.WalletLedgerEntry pendingEntry;
}

class InitiateWalletSpendUseCase {
  InitiateWalletSpendUseCase({
    required WalletRepository walletRepository,
    required BundleRepository bundleRepository,
    required BundleSignatureService bundleSignatureService,
    WalletEventBundleMapper? mapper,
    DateTime Function()? now,
  }) : _walletRepository = walletRepository,
       _bundleRepository = bundleRepository,
       _bundleSignatureService = bundleSignatureService,
       _mapper = mapper ?? const WalletEventBundleMapper(),
       _now = now ?? DateTime.now;

  final WalletRepository _walletRepository;
  final BundleRepository _bundleRepository;
  final BundleSignatureService _bundleSignatureService;
  final WalletEventBundleMapper _mapper;
  final DateTime Function() _now;

  Future<WalletSpendDispatchResult> initiate({
    required String localNodeId,
    required String recipientNodeId,
    required int amountMinorUnits,
    String? memo,
    int ttlSeconds = 3600, // Default TTL of 1 hour for spend bundles.
  }) async {
    if (recipientNodeId.trim().isEmpty) {
      throw ArgumentError('Recipient node id must not be empty.');
    }
    if (amountMinorUnits <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    final String trimmedRecipient = recipientNodeId.trim();
    final String? trimmedMemo = memo?.trim();
    final String? normalizedMemo =
        trimmedMemo == null || trimmedMemo.isEmpty ? null : trimmedMemo;
    final dashboard = await _walletRepository.watchDashboard().first;
    if (dashboard.balanceMinorUnits < amountMinorUnits) {
      throw StateError('Insufficient balance for this spend.');
    }

    final DateTime createdAt = _now();
    final String bundleId = 'wallet-spend-${createdAt.microsecondsSinceEpoch}';
    final Bundle unsignedBundle = _mapper.toSpendBundle(
      bundleId: bundleId,
      localNodeId: localNodeId,
      recipientNodeId: trimmedRecipient,
      amountMinorUnits: amountMinorUnits,
      createdAt: createdAt,
      memo: normalizedMemo,
      ttlSeconds: ttlSeconds,
    );

    final Bundle signedBundle = await _bundleSignatureService.sign(
      bundle: unsignedBundle,
      nodeId: localNodeId,
    );

    final ledger.WalletLedgerEntry pendingEntry = ledger.WalletLedgerEntry(
      entryId: signedBundle.bundleId,
      kind: ledger.WalletLedgerEventKind.spend,
      title: 'Pending Spend',
      subtitle: 'To $trimmedRecipient',
      amountMinorUnits: -amountMinorUnits,
      balanceImpactMinorUnits: 0,
      status: ledger.WalletLedgerStatus.pending,
      createdAt: createdAt,
      memo: normalizedMemo,
      counterpartyNodeId: trimmedRecipient,
      sourceBundleId: signedBundle.bundleId,
    );

    await _bundleRepository.save(signedBundle);
    await _walletRepository.appendEntry(pendingEntry);

    return WalletSpendDispatchResult(
      bundle: signedBundle,
      pendingEntry: pendingEntry,
    );
  }
}