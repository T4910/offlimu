import 'package:offlimu/domain/entities/node_identity.dart';

enum RuntimeHealth {
  idle,
  starting,
  discovering,
  connected,
  forwarding,
  syncing,
  degraded,
  stopping,
}

class RuntimeTelemetry {
  const RuntimeTelemetry({
    this.discoveryEvents = 0,
    this.peerUpserts = 0,
    this.duplicatePeerSuppressions = 0,
    this.stalePeerRemovals = 0,
    this.livenessChecks = 0,
    this.livenessFailures = 0,
    this.outboundSendAttempts = 0,
    this.outboundSendSuccesses = 0,
    this.outboundSendFailures = 0,
    this.inboundBundlesReceived = 0,
    this.inboundBundlesRelayed = 0,
    this.inboundAcksReceived = 0,
    this.outboundAcksGenerated = 0,
  });

  final int discoveryEvents;
  final int peerUpserts;
  final int duplicatePeerSuppressions;
  final int stalePeerRemovals;
  final int livenessChecks;
  final int livenessFailures;
  final int outboundSendAttempts;
  final int outboundSendSuccesses;
  final int outboundSendFailures;
  final int inboundBundlesReceived;
  final int inboundBundlesRelayed;
  final int inboundAcksReceived;
  final int outboundAcksGenerated;

  RuntimeTelemetry copyWith({
    int? discoveryEvents,
    int? peerUpserts,
    int? duplicatePeerSuppressions,
    int? stalePeerRemovals,
    int? livenessChecks,
    int? livenessFailures,
    int? outboundSendAttempts,
    int? outboundSendSuccesses,
    int? outboundSendFailures,
    int? inboundBundlesReceived,
    int? inboundBundlesRelayed,
    int? inboundAcksReceived,
    int? outboundAcksGenerated,
  }) {
    return RuntimeTelemetry(
      discoveryEvents: discoveryEvents ?? this.discoveryEvents,
      peerUpserts: peerUpserts ?? this.peerUpserts,
      duplicatePeerSuppressions:
          duplicatePeerSuppressions ?? this.duplicatePeerSuppressions,
      stalePeerRemovals: stalePeerRemovals ?? this.stalePeerRemovals,
      livenessChecks: livenessChecks ?? this.livenessChecks,
      livenessFailures: livenessFailures ?? this.livenessFailures,
      outboundSendAttempts: outboundSendAttempts ?? this.outboundSendAttempts,
      outboundSendSuccesses:
          outboundSendSuccesses ?? this.outboundSendSuccesses,
      outboundSendFailures: outboundSendFailures ?? this.outboundSendFailures,
      inboundBundlesReceived:
          inboundBundlesReceived ?? this.inboundBundlesReceived,
      inboundBundlesRelayed:
          inboundBundlesRelayed ?? this.inboundBundlesRelayed,
      inboundAcksReceived: inboundAcksReceived ?? this.inboundAcksReceived,
      outboundAcksGenerated:
          outboundAcksGenerated ?? this.outboundAcksGenerated,
    );
  }
}

class NodeRuntimeState {
  const NodeRuntimeState({
    required this.identity,
    required this.health,
    required this.discoveredPeers,
    required this.pendingBundles,
    required this.gatewayEnabled,
    required this.telemetry,
  });

  final NodeIdentity identity;
  final RuntimeHealth health;
  final int discoveredPeers;
  final int pendingBundles;
  final bool gatewayEnabled;
  final RuntimeTelemetry telemetry;
}
