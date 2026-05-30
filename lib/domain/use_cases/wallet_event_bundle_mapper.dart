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

  Bundle toConfirmationBundle({
    required String bundleId,
    required String localNodeId,
    required String sourceSpendBundleId,
    required String recipientNodeId,
    required int amountMinorUnits,
    required DateTime createdAt,
    String? memo,
    int ttlSeconds = 3600,
  }) {
    return Bundle(
      bundleId: bundleId,
      type: Bundle.typeWalletConfirmation,
      sourceNodeId: localNodeId,
      destinationNodeId: recipientNodeId,
      destinationScope: BundleDestinationScope.direct,
      ackForBundleId: sourceSpendBundleId,
      payload: jsonEncode(<String, Object?>{
        'kind': 'confirmation',
        'sourceSpendBundleId': sourceSpendBundleId,
        'recipientNodeId': recipientNodeId,
        'amountMinorUnits': amountMinorUnits,
        'memo': memo,
        'createdAtMs': createdAt.millisecondsSinceEpoch,
      }),
      appId: walletAppId,
      createdAt: createdAt,
      ttlSeconds: ttlSeconds,
      acknowledged: true,
    );
  }

  Bundle toRejectionBundle({
    required String bundleId,
    required String localNodeId,
    required String sourceSpendBundleId,
    required String recipientNodeId,
    required int amountMinorUnits,
    required DateTime createdAt,
    required String reason,
    String? memo,
    int ttlSeconds = 3600,
  }) {
    return Bundle(
      bundleId: bundleId,
      type: Bundle.typeWalletRejection,
      sourceNodeId: localNodeId,
      destinationNodeId: recipientNodeId,
      destinationScope: BundleDestinationScope.direct,
      ackForBundleId: sourceSpendBundleId,
      payload: jsonEncode(<String, Object?>{
        'kind': 'rejection',
        'sourceSpendBundleId': sourceSpendBundleId,
        'recipientNodeId': recipientNodeId,
        'amountMinorUnits': amountMinorUnits,
        'memo': memo,
        'reason': reason,
        'createdAtMs': createdAt.millisecondsSinceEpoch,
      }),
      appId: walletAppId,
      createdAt: createdAt,
      ttlSeconds: ttlSeconds,
      acknowledged: true,
    );
  }

  WalletSpendPayload? decodeSpendPayload(Bundle bundle) {
    final Map<String, Object?>? payload = _decodeObjectPayload(bundle.payload);
    if (payload == null || payload['kind'] != 'spend') {
      return null;
    }

    final amountMinorUnits = (payload['amountMinorUnits'] as num?)?.toInt();
    final recipientNodeId = payload['recipientNodeId'] as String?;
    final createdAtMs = (payload['createdAtMs'] as num?)?.toInt();
    if (amountMinorUnits == null || recipientNodeId == null || createdAtMs == null) {
      return null;
    }

    return WalletSpendPayload(
      recipientNodeId: recipientNodeId,
      amountMinorUnits: amountMinorUnits,
      memo: payload['memo'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }

  WalletReconciliationPayload? decodeReconciliationPayload(Bundle bundle) {
    final Map<String, Object?>? payload = _decodeObjectPayload(bundle.payload);
    if (payload == null) {
      return null;
    }

    final String? sourceSpendBundleId = payload['sourceSpendBundleId'] as String?;
    final String? recipientNodeId = payload['recipientNodeId'] as String?;
    final int? amountMinorUnits = (payload['amountMinorUnits'] as num?)?.toInt();
    final int? createdAtMs = (payload['createdAtMs'] as num?)?.toInt();
    if (sourceSpendBundleId == null ||
        recipientNodeId == null ||
        amountMinorUnits == null ||
        createdAtMs == null) {
      return null;
    }

    return WalletReconciliationPayload(
      sourceSpendBundleId: sourceSpendBundleId,
      recipientNodeId: recipientNodeId,
      amountMinorUnits: amountMinorUnits,
      memo: payload['memo'] as String?,
      reason: payload['reason'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }

  WalletRewardPayload? decodeRewardPayload(Bundle bundle) {
    final Map<String, Object?>? payload = _decodeObjectPayload(bundle.payload);
    if (payload == null || payload['kind'] != 'reward') {
      return null;
    }

    final int? amountMinorUnits = (payload['amountMinorUnits'] as num?)?.toInt();
    final String? rewardKind = payload['rewardKind'] as String?;
    final int? createdAtMs = (payload['createdAtMs'] as num?)?.toInt();
    final String? sourceBundleId = payload['sourceBundleId'] as String?;
    if (amountMinorUnits == null || rewardKind == null || createdAtMs == null) {
      return null;
    }

    return WalletRewardPayload(
      amountMinorUnits: amountMinorUnits,
      rewardKind: rewardKind,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      sourceBundleId: sourceBundleId,
      memo: payload['memo'] as String?,
    );
  }

  Map<String, Object?>? _decodeObjectPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final Object? parsed = jsonDecode(payload);
      if (parsed is! Map) {
        return null;
      }
      return parsed.cast<String, Object?>();
    } catch (_) {
      return null;
    }
  }
}

class WalletRewardPayload {
  const WalletRewardPayload({
    required this.amountMinorUnits,
    required this.rewardKind,
    required this.createdAt,
    this.sourceBundleId,
    this.memo,
  });

  final int amountMinorUnits;
  final String rewardKind; // e.g. 'relay' or 'gateway'
  final DateTime createdAt;
  final String? sourceBundleId;
  final String? memo;
}

class WalletSpendPayload {
  const WalletSpendPayload({
    required this.recipientNodeId,
    required this.amountMinorUnits,
    required this.createdAt,
    this.memo,
  });

  final String recipientNodeId;
  final int amountMinorUnits;
  final DateTime createdAt;
  final String? memo;
}

class WalletReconciliationPayload {
  const WalletReconciliationPayload({
    required this.sourceSpendBundleId,
    required this.recipientNodeId,
    required this.amountMinorUnits,
    required this.createdAt,
    this.memo,
    this.reason,
  });

  final String sourceSpendBundleId;
  final String recipientNodeId;
  final int amountMinorUnits;
  final DateTime createdAt;
  final String? memo;
  final String? reason;
}