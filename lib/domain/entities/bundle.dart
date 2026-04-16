import 'dart:convert';

enum BundleDestinationScope { direct, broadcast }

enum BundlePriority { low, normal, high, critical }

class Bundle {
  const Bundle({
    required this.bundleId,
    required this.type,
    required this.sourceNodeId,
    this.sourcePublicKey,
    this.destinationNodeId,
    this.destinationScope = BundleDestinationScope.direct,
    this.priority = BundlePriority.normal,
    this.ackForBundleId,
    this.payload,
    this.payloadReference,
    this.signature,
    this.appId = 'offlimu.chat',
    required this.createdAt,
    this.expiresAtOverride,
    required this.ttlSeconds,
    this.hopCount = 0,
    this.acknowledged = false,
    this.sentAt,
    this.failedAttempts = 0,
    this.lastError,
  });

  static const String typeChatMessage = 'chat_message';
  static const String typeFileShareMetadata = 'file_share_metadata';
  static const String typeFileShareChunk = 'file_share_chunk';
  static const String typeAck = 'ack';
  static const String typeSyncRejection = 'sync_rejection';

  final String bundleId;
  final String type;
  final String sourceNodeId;
  final String? sourcePublicKey;
  final String? destinationNodeId;
  final BundleDestinationScope destinationScope;
  final BundlePriority priority;
  final String? ackForBundleId;
  final String? payload;
  final String? payloadReference;
  final String? signature;
  final String appId;
  final DateTime createdAt;
  final DateTime? expiresAtOverride;
  final int ttlSeconds;
  final int hopCount;
  final bool acknowledged;
  final DateTime? sentAt;
  final int failedAttempts;
  final String? lastError;

  bool get isAck => type == typeAck;
  bool get isSyncRejection => type == typeSyncRejection;

  String get signaturePayload => jsonEncode(<String, Object?>{
    'bundleId': bundleId,
    'type': type,
    'sourceNodeId': sourceNodeId,
    'sourcePublicKey': sourcePublicKey,
    'destinationNodeId': destinationNodeId,
    'destinationScope': destinationScope.name,
    'priority': priority.name,
    'ackForBundleId': ackForBundleId,
    'payload': payload,
    'payloadReference': payloadReference,
    'appId': appId,
    'createdAtMs': createdAt.millisecondsSinceEpoch,
    'expiresAtMs': expiresAtOverride?.millisecondsSinceEpoch,
    'ttlSeconds': ttlSeconds,
    'hopCount': hopCount,
  });

  bool get isBroadcast =>
      destinationScope == BundleDestinationScope.broadcast ||
      destinationNodeId == null;
  bool get hasInlinePayload => (payload ?? '').isNotEmpty;
  bool get hasPayloadReference => (payloadReference ?? '').isNotEmpty;

  DateTime get expiresAt =>
      expiresAtOverride ?? createdAt.add(Duration(seconds: ttlSeconds));
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  static BundleDestinationScope destinationScopeFromWire(String? value) {
    return switch (value) {
      'broadcast' => BundleDestinationScope.broadcast,
      _ => BundleDestinationScope.direct,
    };
  }

  static BundlePriority priorityFromWire(String? value) {
    return switch (value) {
      'low' => BundlePriority.low,
      'high' => BundlePriority.high,
      'critical' => BundlePriority.critical,
      _ => BundlePriority.normal,
    };
  }

  bool isForwardable({required int maxHopCount}) {
    return !isExpired && hopCount < maxHopCount;
  }

  Bundle copyWith({
    String? bundleId,
    String? type,
    String? sourceNodeId,
    String? sourcePublicKey,
    String? destinationNodeId,
    BundleDestinationScope? destinationScope,
    BundlePriority? priority,
    String? ackForBundleId,
    String? payload,
    String? payloadReference,
    String? signature,
    String? appId,
    DateTime? createdAt,
    DateTime? expiresAtOverride,
    int? ttlSeconds,
    int? hopCount,
    bool? acknowledged,
    DateTime? sentAt,
    int? failedAttempts,
    String? lastError,
  }) {
    return Bundle(
      bundleId: bundleId ?? this.bundleId,
      type: type ?? this.type,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      sourcePublicKey: sourcePublicKey ?? this.sourcePublicKey,
      destinationNodeId: destinationNodeId ?? this.destinationNodeId,
      destinationScope: destinationScope ?? this.destinationScope,
      priority: priority ?? this.priority,
      ackForBundleId: ackForBundleId ?? this.ackForBundleId,
      payload: payload ?? this.payload,
      payloadReference: payloadReference ?? this.payloadReference,
      signature: signature ?? this.signature,
      appId: appId ?? this.appId,
      createdAt: createdAt ?? this.createdAt,
      expiresAtOverride: expiresAtOverride ?? this.expiresAtOverride,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
      hopCount: hopCount ?? this.hopCount,
      acknowledged: acknowledged ?? this.acknowledged,
      sentAt: sentAt ?? this.sentAt,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lastError: lastError ?? this.lastError,
    );
  }
}
