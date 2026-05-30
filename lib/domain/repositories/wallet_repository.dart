import 'package:offlimu/domain/entities/wallet_ledger_entry.dart';

abstract interface class WalletRepository {
  Future<void> appendEntry(WalletLedgerEntry entry);

  Future<void> seedIfEmpty();

  Stream<WalletLedgerDashboard> watchDashboard({
    int recentLimit = 3,
    int rewardLimit = 4,
    int logLimit = 6,
  });
}
