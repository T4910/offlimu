enum WalletLedgerEventKind {
  openingGrant,
  relayReward,
  gatewayReward,
  spend,
  confirmation,
  rejection,
}

enum WalletLedgerStatus { confirmed, pending, rejected }

class WalletLedgerEntry {
  const WalletLedgerEntry({
    required this.entryId,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.amountMinorUnits,
    required this.balanceImpactMinorUnits,
    required this.status,
    required this.createdAt,
    this.memo,
    this.counterpartyNodeId,
    this.sourceBundleId,
  });

  final String entryId;
  final WalletLedgerEventKind kind;
  final String title;
  final String subtitle;
  final int amountMinorUnits;
  final int balanceImpactMinorUnits;
  final WalletLedgerStatus status;
  final DateTime createdAt;
  final String? memo;
  final String? counterpartyNodeId;
  final String? sourceBundleId;

  bool get isCredit => amountMinorUnits > 0;
  bool get isDebit => amountMinorUnits < 0;
  bool get impactsBalance => balanceImpactMinorUnits != 0;
}

class WalletLedgerDashboard {
  const WalletLedgerDashboard({
    required this.balanceMinorUnits,
    required this.availableBalanceMinorUnits,
    required this.relayRewardsMinorUnits,
    required this.gatewayRewardsMinorUnits,
    required this.rewardTotalMinorUnits,
    required this.pendingRewardMinorUnits,
    required this.pendingSpendCount,
    required this.pendingSpendMinorUnits,
    required this.trustScore,
    required this.participationGrade,
    required this.estimatedBundleBytes,
    required this.lastUpdated,
    required this.recentEntries,
    required this.paymentEntries,
    required this.rewardEntries,
    required this.logEntries,
  });

  factory WalletLedgerDashboard.empty() {
    return WalletLedgerDashboard(
      // Neutral/empty dashboard state — real values come from the persisted DB.
      balanceMinorUnits: 0,
      availableBalanceMinorUnits: 0,
      relayRewardsMinorUnits: 0,
      gatewayRewardsMinorUnits: 0,
      rewardTotalMinorUnits: 0,
      pendingRewardMinorUnits: 0,
      pendingSpendCount: 0,
      pendingSpendMinorUnits: 0,
      trustScore: 0.0,
      participationGrade: '',
      estimatedBundleBytes: 0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
      recentEntries: const <WalletLedgerEntry>[],
      paymentEntries: const <WalletLedgerEntry>[],
      rewardEntries: const <WalletLedgerEntry>[],
      logEntries: const <WalletLedgerEntry>[],
    );
  }

  final int balanceMinorUnits;
  final int availableBalanceMinorUnits;
  final int relayRewardsMinorUnits;
  final int gatewayRewardsMinorUnits;
  final int rewardTotalMinorUnits;
  final int pendingRewardMinorUnits;
  final int pendingSpendCount;
  final int pendingSpendMinorUnits;
  final double trustScore;
  final String participationGrade;
  final int estimatedBundleBytes;
  final DateTime lastUpdated;
  final List<WalletLedgerEntry> recentEntries;
  final List<WalletLedgerEntry> paymentEntries;
  final List<WalletLedgerEntry> rewardEntries;
  final List<WalletLedgerEntry> logEntries;
}
