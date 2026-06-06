import 'package:drift/drift.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart' as ledger;
import 'package:offlimu/domain/repositories/wallet_repository.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';

class DriftWalletRepository implements WalletRepository {
  DriftWalletRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> appendEntry(ledger.WalletLedgerEntry entry) async {
    await _db
        .into(_db.walletLedgerEntries)
        .insertOnConflictUpdate(
          WalletLedgerEntriesCompanion(
            entryId: Value<String>(entry.entryId),
            kind: Value<String>(entry.kind.name),
            title: Value<String>(entry.title),
            subtitle: Value<String>(entry.subtitle),
            amountMinorUnits: Value<int>(entry.amountMinorUnits),
            balanceImpactMinorUnits: Value<int>(entry.balanceImpactMinorUnits),
            status: Value<String>(entry.status.name),
            createdAtMs: Value<int>(entry.createdAt.millisecondsSinceEpoch),
            memo: Value<String?>(entry.memo),
            counterpartyNodeId: Value<String?>(entry.counterpartyNodeId),
            sourceBundleId: Value<String?>(entry.sourceBundleId),
          ),
        );
  }

  @override
  Stream<ledger.WalletLedgerDashboard> watchDashboard({
    int recentLimit = 3,
    int rewardLimit = 4,
    int logLimit = 6,
  }) async* {
    final query = (_db.select(_db.walletLedgerEntries)
      ..orderBy(<OrderingTerm Function($WalletLedgerEntriesTable)>[
        (tbl) => OrderingTerm.desc(tbl.createdAtMs),
      ]));

    yield* query.watch().map(
      (rows) => _toDashboard(
        rows: rows,
        recentLimit: recentLimit,
        rewardLimit: rewardLimit,
        logLimit: logLimit,
      ),
    );
  }

  ledger.WalletLedgerDashboard _toDashboard({
    required List<WalletLedgerEntry> rows,
    required int recentLimit,
    required int rewardLimit,
    required int logLimit,
  }) {
    final entries = rows.map(_toEntry).toList(growable: false);
    final rewardEntries = entries
        .where(
          (entry) =>
              entry.kind == ledger.WalletLedgerEventKind.relayReward ||
              entry.kind == ledger.WalletLedgerEventKind.gatewayReward,
        )
        .take(rewardLimit)
        .toList(growable: false);
    final paymentEntries = entries
        .where(
          (entry) =>
              entry.kind == ledger.WalletLedgerEventKind.spend ||
              entry.kind == ledger.WalletLedgerEventKind.confirmation ||
              entry.kind == ledger.WalletLedgerEventKind.rejection,
        )
        .take(logLimit)
        .toList(growable: false);
    final recentEntries = entries.take(recentLimit).toList(growable: false);
    final logEntries = entries
        .where(
          (entry) => entry.kind != ledger.WalletLedgerEventKind.openingGrant,
        )
        .take(logLimit)
        .toList(growable: false);

    final balanceMinorUnits = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.balanceImpactMinorUnits,
    );
    final relayRewardsMinorUnits = rewardEntries
        .where(
          (entry) => entry.kind == ledger.WalletLedgerEventKind.relayReward,
        )
        .fold<int>(0, (sum, entry) => sum + entry.amountMinorUnits);
    final gatewayRewardsMinorUnits = rewardEntries
        .where(
          (entry) => entry.kind == ledger.WalletLedgerEventKind.gatewayReward,
        )
        .fold<int>(0, (sum, entry) => sum + entry.amountMinorUnits);
    final rewardTotalMinorUnits = rewardEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.amountMinorUnits,
    );
    final resolvedSpendSourceIds = entries
        .where(
          (entry) =>
              entry.status != ledger.WalletLedgerStatus.pending &&
              entry.sourceBundleId != null,
        )
        .map((entry) => entry.sourceBundleId!)
        .toSet();
    final pendingRewardMinorUnits = entries
        .where(
          (entry) =>
              (entry.kind == ledger.WalletLedgerEventKind.relayReward ||
                  entry.kind == ledger.WalletLedgerEventKind.gatewayReward) &&
              entry.status == ledger.WalletLedgerStatus.pending,
        )
        .fold<int>(0, (sum, entry) => sum + entry.amountMinorUnits.abs());
    final pendingSpendCount = entries
        .where(
          (entry) =>
              entry.kind == ledger.WalletLedgerEventKind.spend &&
              entry.status == ledger.WalletLedgerStatus.pending &&
              (entry.sourceBundleId == null ||
                  !resolvedSpendSourceIds.contains(entry.sourceBundleId)),
        )
        .length;
    final pendingSpendMinorUnits = entries
        .where(
          (entry) =>
              entry.kind == ledger.WalletLedgerEventKind.spend &&
              entry.status == ledger.WalletLedgerStatus.pending &&
              (entry.sourceBundleId == null ||
                  !resolvedSpendSourceIds.contains(entry.sourceBundleId)),
        )
        .fold<int>(0, (sum, entry) => sum + entry.amountMinorUnits.abs());
    final availableBalanceMinorUnits =
        (balanceMinorUnits - pendingSpendMinorUnits).clamp(
          0,
          balanceMinorUnits,
        );
    final trustScore = _deriveTrustScore(entries);
    final participationGrade = _deriveGrade(trustScore);
    final estimatedBundleBytes = 640 + entries.length * 144;
    final lastUpdated = entries.isEmpty
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : entries.first.createdAt;

    return ledger.WalletLedgerDashboard(
      balanceMinorUnits: balanceMinorUnits,
      availableBalanceMinorUnits: availableBalanceMinorUnits,
      relayRewardsMinorUnits: relayRewardsMinorUnits,
      gatewayRewardsMinorUnits: gatewayRewardsMinorUnits,
      rewardTotalMinorUnits: rewardTotalMinorUnits,
      pendingRewardMinorUnits: pendingRewardMinorUnits,
      pendingSpendCount: pendingSpendCount,
      pendingSpendMinorUnits: pendingSpendMinorUnits,
      trustScore: trustScore,
      participationGrade: participationGrade,
      estimatedBundleBytes: estimatedBundleBytes,
      lastUpdated: lastUpdated,
      recentEntries: recentEntries,
      paymentEntries: paymentEntries,
      rewardEntries: rewardEntries,
      logEntries: logEntries,
    );
  }

  ledger.WalletLedgerEntry _toEntry(WalletLedgerEntry row) {
    return ledger.WalletLedgerEntry(
      entryId: row.entryId,
      kind: _kindFromWire(row.kind),
      title: row.title,
      subtitle: row.subtitle,
      amountMinorUnits: row.amountMinorUnits,
      balanceImpactMinorUnits: row.balanceImpactMinorUnits,
      status: _statusFromWire(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      memo: row.memo,
      counterpartyNodeId: row.counterpartyNodeId,
      sourceBundleId: row.sourceBundleId,
    );
  }

  double _deriveTrustScore(List<ledger.WalletLedgerEntry> entries) {
    final rewardEntries = entries
        .where(
          (entry) =>
              entry.kind == ledger.WalletLedgerEventKind.relayReward ||
              entry.kind == ledger.WalletLedgerEventKind.gatewayReward,
        )
        .toList(growable: false);
    final confirmedRewards = rewardEntries
        .where((entry) => entry.status == ledger.WalletLedgerStatus.confirmed)
        .length;
    if (confirmedRewards == 0) {
      return 0.0;
    }

    final rejectedRewards = rewardEntries
        .where((entry) => entry.status == ledger.WalletLedgerStatus.rejected)
        .length;
    final pendingRewards = rewardEntries
        .where((entry) => entry.status == ledger.WalletLedgerStatus.pending)
        .length;
    final confirmedRelayRewards = rewardEntries
        .where(
          (entry) =>
              entry.kind == ledger.WalletLedgerEventKind.relayReward &&
              entry.status == ledger.WalletLedgerStatus.confirmed,
        )
        .length;

    final reliabilityDenominator =
        confirmedRewards + rejectedRewards + pendingRewards;
    final reliability = reliabilityDenominator == 0
        ? 0.0
        : (confirmedRewards / reliabilityDenominator).clamp(0.0, 1.0);
    final volume = (confirmedRewards / 12).clamp(0.0, 1.0);
    final relayParticipation = (confirmedRelayRewards / 6).clamp(0.0, 1.0);

    final score =
        (reliability * 0.45) + (volume * 0.25) + (relayParticipation * 0.30);
    final cappedScore = confirmedRelayRewards == 0
        ? score.clamp(0.0, 0.55)
        : score.clamp(0.0, 1.0);
    return cappedScore.toDouble();
  }

  String _deriveGrade(double trustScore) {
    if (trustScore <= 0) {
      return 'Unrated';
    }
    if (trustScore >= 0.95) {
      return 'A+';
    }
    if (trustScore >= 0.90) {
      return 'A';
    }
    if (trustScore >= 0.85) {
      return 'A-';
    }
    if (trustScore >= 0.80) {
      return 'B+';
    }
    if (trustScore >= 0.70) {
      return 'B';
    }
    if (trustScore >= 0.55) {
      return 'C';
    }
    return 'D';
  }

  ledger.WalletLedgerEventKind _kindFromWire(String value) {
    return switch (value) {
      'openingGrant' => ledger.WalletLedgerEventKind.openingGrant,
      'relayReward' => ledger.WalletLedgerEventKind.relayReward,
      'gatewayReward' => ledger.WalletLedgerEventKind.gatewayReward,
      'confirmation' => ledger.WalletLedgerEventKind.confirmation,
      'rejection' => ledger.WalletLedgerEventKind.rejection,
      _ => ledger.WalletLedgerEventKind.spend,
    };
  }

  ledger.WalletLedgerStatus _statusFromWire(String value) {
    return switch (value) {
      'pending' => ledger.WalletLedgerStatus.pending,
      'rejected' => ledger.WalletLedgerStatus.rejected,
      _ => ledger.WalletLedgerStatus.confirmed,
    };
  }
}
