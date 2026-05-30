import 'dart:convert';

import 'package:offlimu/domain/entities/bundle.dart';

class WalletEventBundleMapper {
  const WalletEventBundleMapper();

  static const String walletAppId = 'offlimu.wallet';

  Bundle toSpendBundle({
    required String bundleId,
    required String localNodeId,
    required String recipientNodeId,
    required int amountMinorUnits,
    required DateTime createdAt,
    String? memo,
    int ttlSeconds = 3600,
  }) {
    return Bundle(
      bundleId: bundleId,
      type: Bundle.typeWalletSpend,
      sourceNodeId: localNodeId,
      destinationNodeId: recipientNodeId,
      destinationScope: BundleDestinationScope.direct,
      payload: jsonEncode(<String, Object?>{
        'kind': 'spend',
        'recipientNodeId': recipientNodeId,
        'amountMinorUnits': amountMinorUnits,
        'memo': memo,
        'createdAtMs': createdAt.millisecondsSinceEpoch,
      }),
      appId: walletAppId,
      createdAt: createdAt,
      ttlSeconds: ttlSeconds,
    );
  }
}