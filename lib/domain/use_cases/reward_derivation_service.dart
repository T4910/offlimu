import 'package:offlimu/domain/use_cases/reward_issuance_use_case.dart';
import 'package:offlimu/node_runtime/node_runtime.dart';

class RewardDerivationService {
  RewardDerivationService({
    required NodeRuntime runtime,
    required RewardIssuanceUseCase issuance,
    required String localNodeId,
  }) : _runtime = runtime,
       _issuance = issuance,
       _localNodeId = localNodeId;

  final NodeRuntime _runtime;
  final RewardIssuanceUseCase _issuance;
  final String _localNodeId;

  /// Simple derivation heuristic: if we've successfully forwarded any bundles
  /// since the last check, issue a small relay reward.
  Future<void> deriveAndIssueIfEligible() async {
    final telemetry = _runtime.telemetry;
    if (telemetry.outboundSendSuccesses > 0) {
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
