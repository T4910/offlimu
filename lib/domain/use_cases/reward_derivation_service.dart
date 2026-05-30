import 'package:offlimu/domain/use_cases/reward_issuance_use_case.dart';

class RewardDerivationService {
  RewardDerivationService({
    required int Function() outboundSendSuccessesGetter,
    required RewardIssuanceUseCase issuance,
    required String localNodeId,
  }) : _getOutboundSendSuccesses = outboundSendSuccessesGetter,
       _issuance = issuance,
       _localNodeId = localNodeId;

  final int Function() _getOutboundSendSuccesses;
  final RewardIssuanceUseCase _issuance;
  final String _localNodeId;

  /// Simple derivation heuristic: if we've successfully forwarded any bundles
  /// since the last check, issue a small relay reward.
  Future<void> deriveAndIssueIfEligible() async {
    if (_getOutboundSendSuccesses() > 0) {
      // Issue a small relay reward (250 minor units) once per run.
      await _issuance.createPendingReward(
        localNodeId: _localNodeId,
        amountMinorUnits: 250,
        rewardKind: 'relay',
        memo: 'Relay contribution reward',
      );
    }
  }
}
