import 'package:drift/drift.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart' as ledger;
import 'package:offlimu/domain/repositories/wallet_repository.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';

class DriftWalletRepository implements WalletRepository {
  DriftWalletRepository(this._db);

  final AppDatabase _db;

  static final List<ledger.WalletLedgerEntry> _seedEntries =
      <ledger.WalletLedgerEntry>[
    ledger.WalletLedgerEntry(
      entryId: 'wallet-opening-grant',
      kind: ledger.WalletLedgerEventKind.openingGrant,
      title: 'Genesis Grant',
      subtitle: 'Opening balance seeded locally',
      amountMinorUnits: 5000,
      balanceImpactMinorUnits: 5000,
      status: ledger.WalletLedgerStatus.confirmed,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    ),
    ledger.WalletLedgerEntry(
      entryId: 'wallet-relay-reward',
      kind: ledger.WalletLedgerEventKind.relayReward,
      title: 'Relay Reward',
      subtitle: 'Delivered via DTN fanout',
      amountMinorUnits: 1250,
      balanceImpactMinorUnits: 1250,
      status: ledger.WalletLedgerStatus.confirmed,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700003600000),
    ),
    ledger.WalletLedgerEntry(
      entryId: 'wallet-gateway-reward',
      kind: ledger.WalletLedgerEventKind.gatewayReward,
      title: 'Gateway Reward',
      subtitle: 'Sync acknowledgement credited',
      amountMinorUnits: 120,
      balanceImpactMinorUnits: 120,
      status: ledger.WalletLedgerStatus.confirmed,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700007200000),
    ),
    ledger.WalletLedgerEntry(
      entryId: 'wallet-relay-reward-2',
      kind: ledger.WalletLedgerEventKind.relayReward,
      title: 'Relay Reward',
      subtitle: 'Acknowledged on intermediate hop',
      amountMinorUnits: 310,
      balanceImpactMinorUnits: 310,
      status: ledger.WalletLedgerStatus.confirmed,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700008000000),
    ),
    ledger.WalletLedgerEntry(
      entryId: 'wallet-relay-reward-3',
      kind: ledger.WalletLedgerEventKind.relayReward,
      title: 'Relay Reward',
      subtitle: 'Fanout preserved by DTN delivery',
      amountMinorUnits: 150,
      balanceImpactMinorUnits: 150,
      status: ledger.WalletLedgerStatus.confirmed,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700009000000),
    ),
    ledger.WalletLedgerEntry(
      entryId: 'wallet-settled-spend',
      kind: ledger.WalletLedgerEventKind.spend,
      title: 'Settled Spend',
      subtitle: 'Signed transfer reconciled',
      amountMinorUnits: -1830,
      balanceImpactMinorUnits: -1830,
      status: ledger.WalletLedgerStatus.confirmed,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700010800000),
      counterpartyNodeId: 'node-settlement',
    ),
    ledger.WalletLedgerEntry(
      entryId: 'wallet-rejected-spend',
      kind: ledger.WalletLedgerEventKind.rejection,
      title: 'Rejected Spend',
      subtitle: 'Rejected by reconciliation',
      amountMinorUnits: -4500,
      balanceImpactMinorUnits: 0,
      status: ledger.WalletLedgerStatus.rejected,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700014400000),
      counterpartyNodeId: 'node-reject',
      memo: 'Replay protection tripped',
    ),
  ];

  @override
  Future<void> appendEntry(ledger.WalletLedgerEntry entry) async {
    await _db.into(_db.walletLedgerEntries).insertOnConflictUpdate(
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
  Future<void> seedIfEmpty() async {
    final existing = await (_db.select(_db.walletLedgerEntries)..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      return;
    }

  // Commenting out seeding for now to avoid confusion with real entries during development.
    // await _db.transaction(() async {
    //   for (final entry in _seedEntries) {
    //     await appendEntry(entry);
    //   }
    // });
  }

  @override
  Stream<ledger.WalletLedgerDashboard> watchDashboard({
    int recentLimit = 3,
    int rewardLimit = 4,
    int logLimit = 6,
  }) async* {
    await seedIfEmpty();

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
    final logEntries = entries.take(logLimit).toList(growable: false);

    final balanceMinorUnits = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.balanceImpactMinorUnits,
    );
    final relayRewardsMinorUnits = rewardEntries
        .where((entry) => entry.kind == ledger.WalletLedgerEventKind.relayReward)
        .fold<int>(0, (sum, entry) => sum + entry.amountMinorUnits);
    final gatewayRewardsMinorUnits = rewardEntries
        .where((entry) => entry.kind == ledger.WalletLedgerEventKind.gatewayReward)
        .fold<int>(0, (sum, entry) => sum + entry.amountMinorUnits);
    final rewardTotalMinorUnits = rewardEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.amountMinorUnits,
    );
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
              entry.status == ledger.WalletLedgerStatus.pending,
        )
        .length;
    final pendingSpendMinorUnits = entries
        .where(
          (entry) =>
              entry.kind == ledger.WalletLedgerEventKind.spend &&
              entry.status == ledger.WalletLedgerStatus.pending,
        )
        .fold<int>(0, (sum, entry) => sum + entry.amountMinorUnits.abs());
    final trustScore = _deriveTrustScore(entries);
    final participationGrade = _deriveGrade(trustScore);
    final estimatedBundleBytes = 640 + entries.length * 144;
    final lastUpdated = entries.isEmpty
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : entries.first.createdAt;

    return ledger.WalletLedgerDashboard(
      balanceMinorUnits: balanceMinorUnits,
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
    final confirmed = entries
        .where((entry) => entry.status == ledger.WalletLedgerStatus.confirmed)
        .length;
    final rejected = entries
        .where((entry) => entry.status == ledger.WalletLedgerStatus.rejected)
        .length;
    final total = entries.isEmpty ? 1 : entries.length;
    final ratio = (confirmed - rejected).clamp(0, total) / total;
    final score = 0.75 + ratio * 0.2;
    return score.clamp(0.0, 1.0).toDouble();
  }

  String _deriveGrade(double trustScore) {
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
    return 'B';
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
