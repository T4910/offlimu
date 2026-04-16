// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BundleRecordsTable extends BundleRecords
    with TableInfo<$BundleRecordsTable, BundleRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BundleRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bundleIdMeta = const VerificationMeta(
    'bundleId',
  );
  @override
  late final GeneratedColumn<String> bundleId = GeneratedColumn<String>(
    'bundle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNodeIdMeta = const VerificationMeta(
    'sourceNodeId',
  );
  @override
  late final GeneratedColumn<String> sourceNodeId = GeneratedColumn<String>(
    'source_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationNodeIdMeta = const VerificationMeta(
    'destinationNodeId',
  );
  @override
  late final GeneratedColumn<String> destinationNodeId =
      GeneratedColumn<String>(
        'destination_node_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _destinationScopeMeta = const VerificationMeta(
    'destinationScope',
  );
  @override
  late final GeneratedColumn<String> destinationScope = GeneratedColumn<String>(
    'destination_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('direct'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _ackForBundleIdMeta = const VerificationMeta(
    'ackForBundleId',
  );
  @override
  late final GeneratedColumn<String> ackForBundleId = GeneratedColumn<String>(
    'ack_for_bundle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadRefMeta = const VerificationMeta(
    'payloadRef',
  );
  @override
  late final GeneratedColumn<String> payloadRef = GeneratedColumn<String>(
    'payload_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
    'app_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('offlimu.chat'),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMsMeta = const VerificationMeta(
    'expiresAtMs',
  );
  @override
  late final GeneratedColumn<int> expiresAtMs = GeneratedColumn<int>(
    'expires_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ttlSecondsMeta = const VerificationMeta(
    'ttlSeconds',
  );
  @override
  late final GeneratedColumn<int> ttlSeconds = GeneratedColumn<int>(
    'ttl_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hopCountMeta = const VerificationMeta(
    'hopCount',
  );
  @override
  late final GeneratedColumn<int> hopCount = GeneratedColumn<int>(
    'hop_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _acknowledgedMeta = const VerificationMeta(
    'acknowledged',
  );
  @override
  late final GeneratedColumn<bool> acknowledged = GeneratedColumn<bool>(
    'acknowledged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("acknowledged" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sentAtMsMeta = const VerificationMeta(
    'sentAtMs',
  );
  @override
  late final GeneratedColumn<int> sentAtMs = GeneratedColumn<int>(
    'sent_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failedAttemptsMeta = const VerificationMeta(
    'failedAttempts',
  );
  @override
  late final GeneratedColumn<int> failedAttempts = GeneratedColumn<int>(
    'failed_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bundleId,
    type,
    sourceNodeId,
    destinationNodeId,
    destinationScope,
    priority,
    ackForBundleId,
    payload,
    payloadRef,
    signature,
    appId,
    createdAtMs,
    expiresAtMs,
    ttlSeconds,
    hopCount,
    acknowledged,
    sentAtMs,
    failedAttempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bundle_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<BundleRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bundle_id')) {
      context.handle(
        _bundleIdMeta,
        bundleId.isAcceptableOrUnknown(data['bundle_id']!, _bundleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bundleIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('source_node_id')) {
      context.handle(
        _sourceNodeIdMeta,
        sourceNodeId.isAcceptableOrUnknown(
          data['source_node_id']!,
          _sourceNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceNodeIdMeta);
    }
    if (data.containsKey('destination_node_id')) {
      context.handle(
        _destinationNodeIdMeta,
        destinationNodeId.isAcceptableOrUnknown(
          data['destination_node_id']!,
          _destinationNodeIdMeta,
        ),
      );
    }
    if (data.containsKey('destination_scope')) {
      context.handle(
        _destinationScopeMeta,
        destinationScope.isAcceptableOrUnknown(
          data['destination_scope']!,
          _destinationScopeMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('ack_for_bundle_id')) {
      context.handle(
        _ackForBundleIdMeta,
        ackForBundleId.isAcceptableOrUnknown(
          data['ack_for_bundle_id']!,
          _ackForBundleIdMeta,
        ),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('payload_ref')) {
      context.handle(
        _payloadRefMeta,
        payloadRef.isAcceptableOrUnknown(data['payload_ref']!, _payloadRefMeta),
      );
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    }
    if (data.containsKey('app_id')) {
      context.handle(
        _appIdMeta,
        appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('expires_at_ms')) {
      context.handle(
        _expiresAtMsMeta,
        expiresAtMs.isAcceptableOrUnknown(
          data['expires_at_ms']!,
          _expiresAtMsMeta,
        ),
      );
    }
    if (data.containsKey('ttl_seconds')) {
      context.handle(
        _ttlSecondsMeta,
        ttlSeconds.isAcceptableOrUnknown(data['ttl_seconds']!, _ttlSecondsMeta),
      );
    } else if (isInserting) {
      context.missing(_ttlSecondsMeta);
    }
    if (data.containsKey('hop_count')) {
      context.handle(
        _hopCountMeta,
        hopCount.isAcceptableOrUnknown(data['hop_count']!, _hopCountMeta),
      );
    }
    if (data.containsKey('acknowledged')) {
      context.handle(
        _acknowledgedMeta,
        acknowledged.isAcceptableOrUnknown(
          data['acknowledged']!,
          _acknowledgedMeta,
        ),
      );
    }
    if (data.containsKey('sent_at_ms')) {
      context.handle(
        _sentAtMsMeta,
        sentAtMs.isAcceptableOrUnknown(data['sent_at_ms']!, _sentAtMsMeta),
      );
    }
    if (data.containsKey('failed_attempts')) {
      context.handle(
        _failedAttemptsMeta,
        failedAttempts.isAcceptableOrUnknown(
          data['failed_attempts']!,
          _failedAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bundleId};
  @override
  BundleRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BundleRecord(
      bundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bundle_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      sourceNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_node_id'],
      )!,
      destinationNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_node_id'],
      ),
      destinationScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_scope'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      ackForBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ack_for_bundle_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      payloadRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_ref'],
      ),
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      ),
      appId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_id'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      ),
      ttlSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ttl_seconds'],
      )!,
      hopCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hop_count'],
      )!,
      acknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}acknowledged'],
      )!,
      sentAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_at_ms'],
      ),
      failedAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $BundleRecordsTable createAlias(String alias) {
    return $BundleRecordsTable(attachedDatabase, alias);
  }
}

class BundleRecord extends DataClass implements Insertable<BundleRecord> {
  final String bundleId;
  final String type;
  final String sourceNodeId;
  final String? destinationNodeId;
  final String destinationScope;
  final String priority;
  final String? ackForBundleId;
  final String? payload;
  final String? payloadRef;
  final String? signature;
  final String appId;
  final int createdAtMs;
  final int? expiresAtMs;
  final int ttlSeconds;
  final int hopCount;
  final bool acknowledged;
  final int? sentAtMs;
  final int failedAttempts;
  final String? lastError;
  const BundleRecord({
    required this.bundleId,
    required this.type,
    required this.sourceNodeId,
    this.destinationNodeId,
    required this.destinationScope,
    required this.priority,
    this.ackForBundleId,
    this.payload,
    this.payloadRef,
    this.signature,
    required this.appId,
    required this.createdAtMs,
    this.expiresAtMs,
    required this.ttlSeconds,
    required this.hopCount,
    required this.acknowledged,
    this.sentAtMs,
    required this.failedAttempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bundle_id'] = Variable<String>(bundleId);
    map['type'] = Variable<String>(type);
    map['source_node_id'] = Variable<String>(sourceNodeId);
    if (!nullToAbsent || destinationNodeId != null) {
      map['destination_node_id'] = Variable<String>(destinationNodeId);
    }
    map['destination_scope'] = Variable<String>(destinationScope);
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || ackForBundleId != null) {
      map['ack_for_bundle_id'] = Variable<String>(ackForBundleId);
    }
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    if (!nullToAbsent || payloadRef != null) {
      map['payload_ref'] = Variable<String>(payloadRef);
    }
    if (!nullToAbsent || signature != null) {
      map['signature'] = Variable<String>(signature);
    }
    map['app_id'] = Variable<String>(appId);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || expiresAtMs != null) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs);
    }
    map['ttl_seconds'] = Variable<int>(ttlSeconds);
    map['hop_count'] = Variable<int>(hopCount);
    map['acknowledged'] = Variable<bool>(acknowledged);
    if (!nullToAbsent || sentAtMs != null) {
      map['sent_at_ms'] = Variable<int>(sentAtMs);
    }
    map['failed_attempts'] = Variable<int>(failedAttempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  BundleRecordsCompanion toCompanion(bool nullToAbsent) {
    return BundleRecordsCompanion(
      bundleId: Value(bundleId),
      type: Value(type),
      sourceNodeId: Value(sourceNodeId),
      destinationNodeId: destinationNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationNodeId),
      destinationScope: Value(destinationScope),
      priority: Value(priority),
      ackForBundleId: ackForBundleId == null && nullToAbsent
          ? const Value.absent()
          : Value(ackForBundleId),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      payloadRef: payloadRef == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadRef),
      signature: signature == null && nullToAbsent
          ? const Value.absent()
          : Value(signature),
      appId: Value(appId),
      createdAtMs: Value(createdAtMs),
      expiresAtMs: expiresAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAtMs),
      ttlSeconds: Value(ttlSeconds),
      hopCount: Value(hopCount),
      acknowledged: Value(acknowledged),
      sentAtMs: sentAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAtMs),
      failedAttempts: Value(failedAttempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory BundleRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BundleRecord(
      bundleId: serializer.fromJson<String>(json['bundleId']),
      type: serializer.fromJson<String>(json['type']),
      sourceNodeId: serializer.fromJson<String>(json['sourceNodeId']),
      destinationNodeId: serializer.fromJson<String?>(
        json['destinationNodeId'],
      ),
      destinationScope: serializer.fromJson<String>(json['destinationScope']),
      priority: serializer.fromJson<String>(json['priority']),
      ackForBundleId: serializer.fromJson<String?>(json['ackForBundleId']),
      payload: serializer.fromJson<String?>(json['payload']),
      payloadRef: serializer.fromJson<String?>(json['payloadRef']),
      signature: serializer.fromJson<String?>(json['signature']),
      appId: serializer.fromJson<String>(json['appId']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      expiresAtMs: serializer.fromJson<int?>(json['expiresAtMs']),
      ttlSeconds: serializer.fromJson<int>(json['ttlSeconds']),
      hopCount: serializer.fromJson<int>(json['hopCount']),
      acknowledged: serializer.fromJson<bool>(json['acknowledged']),
      sentAtMs: serializer.fromJson<int?>(json['sentAtMs']),
      failedAttempts: serializer.fromJson<int>(json['failedAttempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bundleId': serializer.toJson<String>(bundleId),
      'type': serializer.toJson<String>(type),
      'sourceNodeId': serializer.toJson<String>(sourceNodeId),
      'destinationNodeId': serializer.toJson<String?>(destinationNodeId),
      'destinationScope': serializer.toJson<String>(destinationScope),
      'priority': serializer.toJson<String>(priority),
      'ackForBundleId': serializer.toJson<String?>(ackForBundleId),
      'payload': serializer.toJson<String?>(payload),
      'payloadRef': serializer.toJson<String?>(payloadRef),
      'signature': serializer.toJson<String?>(signature),
      'appId': serializer.toJson<String>(appId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'expiresAtMs': serializer.toJson<int?>(expiresAtMs),
      'ttlSeconds': serializer.toJson<int>(ttlSeconds),
      'hopCount': serializer.toJson<int>(hopCount),
      'acknowledged': serializer.toJson<bool>(acknowledged),
      'sentAtMs': serializer.toJson<int?>(sentAtMs),
      'failedAttempts': serializer.toJson<int>(failedAttempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  BundleRecord copyWith({
    String? bundleId,
    String? type,
    String? sourceNodeId,
    Value<String?> destinationNodeId = const Value.absent(),
    String? destinationScope,
    String? priority,
    Value<String?> ackForBundleId = const Value.absent(),
    Value<String?> payload = const Value.absent(),
    Value<String?> payloadRef = const Value.absent(),
    Value<String?> signature = const Value.absent(),
    String? appId,
    int? createdAtMs,
    Value<int?> expiresAtMs = const Value.absent(),
    int? ttlSeconds,
    int? hopCount,
    bool? acknowledged,
    Value<int?> sentAtMs = const Value.absent(),
    int? failedAttempts,
    Value<String?> lastError = const Value.absent(),
  }) => BundleRecord(
    bundleId: bundleId ?? this.bundleId,
    type: type ?? this.type,
    sourceNodeId: sourceNodeId ?? this.sourceNodeId,
    destinationNodeId: destinationNodeId.present
        ? destinationNodeId.value
        : this.destinationNodeId,
    destinationScope: destinationScope ?? this.destinationScope,
    priority: priority ?? this.priority,
    ackForBundleId: ackForBundleId.present
        ? ackForBundleId.value
        : this.ackForBundleId,
    payload: payload.present ? payload.value : this.payload,
    payloadRef: payloadRef.present ? payloadRef.value : this.payloadRef,
    signature: signature.present ? signature.value : this.signature,
    appId: appId ?? this.appId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    expiresAtMs: expiresAtMs.present ? expiresAtMs.value : this.expiresAtMs,
    ttlSeconds: ttlSeconds ?? this.ttlSeconds,
    hopCount: hopCount ?? this.hopCount,
    acknowledged: acknowledged ?? this.acknowledged,
    sentAtMs: sentAtMs.present ? sentAtMs.value : this.sentAtMs,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  BundleRecord copyWithCompanion(BundleRecordsCompanion data) {
    return BundleRecord(
      bundleId: data.bundleId.present ? data.bundleId.value : this.bundleId,
      type: data.type.present ? data.type.value : this.type,
      sourceNodeId: data.sourceNodeId.present
          ? data.sourceNodeId.value
          : this.sourceNodeId,
      destinationNodeId: data.destinationNodeId.present
          ? data.destinationNodeId.value
          : this.destinationNodeId,
      destinationScope: data.destinationScope.present
          ? data.destinationScope.value
          : this.destinationScope,
      priority: data.priority.present ? data.priority.value : this.priority,
      ackForBundleId: data.ackForBundleId.present
          ? data.ackForBundleId.value
          : this.ackForBundleId,
      payload: data.payload.present ? data.payload.value : this.payload,
      payloadRef: data.payloadRef.present
          ? data.payloadRef.value
          : this.payloadRef,
      signature: data.signature.present ? data.signature.value : this.signature,
      appId: data.appId.present ? data.appId.value : this.appId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
      ttlSeconds: data.ttlSeconds.present
          ? data.ttlSeconds.value
          : this.ttlSeconds,
      hopCount: data.hopCount.present ? data.hopCount.value : this.hopCount,
      acknowledged: data.acknowledged.present
          ? data.acknowledged.value
          : this.acknowledged,
      sentAtMs: data.sentAtMs.present ? data.sentAtMs.value : this.sentAtMs,
      failedAttempts: data.failedAttempts.present
          ? data.failedAttempts.value
          : this.failedAttempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BundleRecord(')
          ..write('bundleId: $bundleId, ')
          ..write('type: $type, ')
          ..write('sourceNodeId: $sourceNodeId, ')
          ..write('destinationNodeId: $destinationNodeId, ')
          ..write('destinationScope: $destinationScope, ')
          ..write('priority: $priority, ')
          ..write('ackForBundleId: $ackForBundleId, ')
          ..write('payload: $payload, ')
          ..write('payloadRef: $payloadRef, ')
          ..write('signature: $signature, ')
          ..write('appId: $appId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('ttlSeconds: $ttlSeconds, ')
          ..write('hopCount: $hopCount, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('sentAtMs: $sentAtMs, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bundleId,
    type,
    sourceNodeId,
    destinationNodeId,
    destinationScope,
    priority,
    ackForBundleId,
    payload,
    payloadRef,
    signature,
    appId,
    createdAtMs,
    expiresAtMs,
    ttlSeconds,
    hopCount,
    acknowledged,
    sentAtMs,
    failedAttempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BundleRecord &&
          other.bundleId == this.bundleId &&
          other.type == this.type &&
          other.sourceNodeId == this.sourceNodeId &&
          other.destinationNodeId == this.destinationNodeId &&
          other.destinationScope == this.destinationScope &&
          other.priority == this.priority &&
          other.ackForBundleId == this.ackForBundleId &&
          other.payload == this.payload &&
          other.payloadRef == this.payloadRef &&
          other.signature == this.signature &&
          other.appId == this.appId &&
          other.createdAtMs == this.createdAtMs &&
          other.expiresAtMs == this.expiresAtMs &&
          other.ttlSeconds == this.ttlSeconds &&
          other.hopCount == this.hopCount &&
          other.acknowledged == this.acknowledged &&
          other.sentAtMs == this.sentAtMs &&
          other.failedAttempts == this.failedAttempts &&
          other.lastError == this.lastError);
}

class BundleRecordsCompanion extends UpdateCompanion<BundleRecord> {
  final Value<String> bundleId;
  final Value<String> type;
  final Value<String> sourceNodeId;
  final Value<String?> destinationNodeId;
  final Value<String> destinationScope;
  final Value<String> priority;
  final Value<String?> ackForBundleId;
  final Value<String?> payload;
  final Value<String?> payloadRef;
  final Value<String?> signature;
  final Value<String> appId;
  final Value<int> createdAtMs;
  final Value<int?> expiresAtMs;
  final Value<int> ttlSeconds;
  final Value<int> hopCount;
  final Value<bool> acknowledged;
  final Value<int?> sentAtMs;
  final Value<int> failedAttempts;
  final Value<String?> lastError;
  final Value<int> rowid;
  const BundleRecordsCompanion({
    this.bundleId = const Value.absent(),
    this.type = const Value.absent(),
    this.sourceNodeId = const Value.absent(),
    this.destinationNodeId = const Value.absent(),
    this.destinationScope = const Value.absent(),
    this.priority = const Value.absent(),
    this.ackForBundleId = const Value.absent(),
    this.payload = const Value.absent(),
    this.payloadRef = const Value.absent(),
    this.signature = const Value.absent(),
    this.appId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.ttlSeconds = const Value.absent(),
    this.hopCount = const Value.absent(),
    this.acknowledged = const Value.absent(),
    this.sentAtMs = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BundleRecordsCompanion.insert({
    required String bundleId,
    required String type,
    required String sourceNodeId,
    this.destinationNodeId = const Value.absent(),
    this.destinationScope = const Value.absent(),
    this.priority = const Value.absent(),
    this.ackForBundleId = const Value.absent(),
    this.payload = const Value.absent(),
    this.payloadRef = const Value.absent(),
    this.signature = const Value.absent(),
    this.appId = const Value.absent(),
    required int createdAtMs,
    this.expiresAtMs = const Value.absent(),
    required int ttlSeconds,
    this.hopCount = const Value.absent(),
    this.acknowledged = const Value.absent(),
    this.sentAtMs = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bundleId = Value(bundleId),
       type = Value(type),
       sourceNodeId = Value(sourceNodeId),
       createdAtMs = Value(createdAtMs),
       ttlSeconds = Value(ttlSeconds);
  static Insertable<BundleRecord> custom({
    Expression<String>? bundleId,
    Expression<String>? type,
    Expression<String>? sourceNodeId,
    Expression<String>? destinationNodeId,
    Expression<String>? destinationScope,
    Expression<String>? priority,
    Expression<String>? ackForBundleId,
    Expression<String>? payload,
    Expression<String>? payloadRef,
    Expression<String>? signature,
    Expression<String>? appId,
    Expression<int>? createdAtMs,
    Expression<int>? expiresAtMs,
    Expression<int>? ttlSeconds,
    Expression<int>? hopCount,
    Expression<bool>? acknowledged,
    Expression<int>? sentAtMs,
    Expression<int>? failedAttempts,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bundleId != null) 'bundle_id': bundleId,
      if (type != null) 'type': type,
      if (sourceNodeId != null) 'source_node_id': sourceNodeId,
      if (destinationNodeId != null) 'destination_node_id': destinationNodeId,
      if (destinationScope != null) 'destination_scope': destinationScope,
      if (priority != null) 'priority': priority,
      if (ackForBundleId != null) 'ack_for_bundle_id': ackForBundleId,
      if (payload != null) 'payload': payload,
      if (payloadRef != null) 'payload_ref': payloadRef,
      if (signature != null) 'signature': signature,
      if (appId != null) 'app_id': appId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (ttlSeconds != null) 'ttl_seconds': ttlSeconds,
      if (hopCount != null) 'hop_count': hopCount,
      if (acknowledged != null) 'acknowledged': acknowledged,
      if (sentAtMs != null) 'sent_at_ms': sentAtMs,
      if (failedAttempts != null) 'failed_attempts': failedAttempts,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BundleRecordsCompanion copyWith({
    Value<String>? bundleId,
    Value<String>? type,
    Value<String>? sourceNodeId,
    Value<String?>? destinationNodeId,
    Value<String>? destinationScope,
    Value<String>? priority,
    Value<String?>? ackForBundleId,
    Value<String?>? payload,
    Value<String?>? payloadRef,
    Value<String?>? signature,
    Value<String>? appId,
    Value<int>? createdAtMs,
    Value<int?>? expiresAtMs,
    Value<int>? ttlSeconds,
    Value<int>? hopCount,
    Value<bool>? acknowledged,
    Value<int?>? sentAtMs,
    Value<int>? failedAttempts,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return BundleRecordsCompanion(
      bundleId: bundleId ?? this.bundleId,
      type: type ?? this.type,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      destinationNodeId: destinationNodeId ?? this.destinationNodeId,
      destinationScope: destinationScope ?? this.destinationScope,
      priority: priority ?? this.priority,
      ackForBundleId: ackForBundleId ?? this.ackForBundleId,
      payload: payload ?? this.payload,
      payloadRef: payloadRef ?? this.payloadRef,
      signature: signature ?? this.signature,
      appId: appId ?? this.appId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
      hopCount: hopCount ?? this.hopCount,
      acknowledged: acknowledged ?? this.acknowledged,
      sentAtMs: sentAtMs ?? this.sentAtMs,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bundleId.present) {
      map['bundle_id'] = Variable<String>(bundleId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sourceNodeId.present) {
      map['source_node_id'] = Variable<String>(sourceNodeId.value);
    }
    if (destinationNodeId.present) {
      map['destination_node_id'] = Variable<String>(destinationNodeId.value);
    }
    if (destinationScope.present) {
      map['destination_scope'] = Variable<String>(destinationScope.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (ackForBundleId.present) {
      map['ack_for_bundle_id'] = Variable<String>(ackForBundleId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (payloadRef.present) {
      map['payload_ref'] = Variable<String>(payloadRef.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (ttlSeconds.present) {
      map['ttl_seconds'] = Variable<int>(ttlSeconds.value);
    }
    if (hopCount.present) {
      map['hop_count'] = Variable<int>(hopCount.value);
    }
    if (acknowledged.present) {
      map['acknowledged'] = Variable<bool>(acknowledged.value);
    }
    if (sentAtMs.present) {
      map['sent_at_ms'] = Variable<int>(sentAtMs.value);
    }
    if (failedAttempts.present) {
      map['failed_attempts'] = Variable<int>(failedAttempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BundleRecordsCompanion(')
          ..write('bundleId: $bundleId, ')
          ..write('type: $type, ')
          ..write('sourceNodeId: $sourceNodeId, ')
          ..write('destinationNodeId: $destinationNodeId, ')
          ..write('destinationScope: $destinationScope, ')
          ..write('priority: $priority, ')
          ..write('ackForBundleId: $ackForBundleId, ')
          ..write('payload: $payload, ')
          ..write('payloadRef: $payloadRef, ')
          ..write('signature: $signature, ')
          ..write('appId: $appId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('ttlSeconds: $ttlSeconds, ')
          ..write('hopCount: $hopCount, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('sentAtMs: $sentAtMs, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeerContactsTable extends PeerContacts
    with TableInfo<$PeerContactsTable, PeerContact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeerContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenMsMeta = const VerificationMeta(
    'lastSeenMs',
  );
  @override
  late final GeneratedColumn<int> lastSeenMs = GeneratedColumn<int>(
    'last_seen_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenCountMeta = const VerificationMeta(
    'seenCount',
  );
  @override
  late final GeneratedColumn<int> seenCount = GeneratedColumn<int>(
    'seen_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    nodeId,
    host,
    port,
    lastSeenMs,
    seenCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'peer_contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeerContact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('last_seen_ms')) {
      context.handle(
        _lastSeenMsMeta,
        lastSeenMs.isAcceptableOrUnknown(
          data['last_seen_ms']!,
          _lastSeenMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMsMeta);
    }
    if (data.containsKey('seen_count')) {
      context.handle(
        _seenCountMeta,
        seenCount.isAcceptableOrUnknown(data['seen_count']!, _seenCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nodeId};
  @override
  PeerContact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeerContact(
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      lastSeenMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_ms'],
      )!,
      seenCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seen_count'],
      )!,
    );
  }

  @override
  $PeerContactsTable createAlias(String alias) {
    return $PeerContactsTable(attachedDatabase, alias);
  }
}

class PeerContact extends DataClass implements Insertable<PeerContact> {
  final String nodeId;
  final String host;
  final int port;
  final int lastSeenMs;
  final int seenCount;
  const PeerContact({
    required this.nodeId,
    required this.host,
    required this.port,
    required this.lastSeenMs,
    required this.seenCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_id'] = Variable<String>(nodeId);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['last_seen_ms'] = Variable<int>(lastSeenMs);
    map['seen_count'] = Variable<int>(seenCount);
    return map;
  }

  PeerContactsCompanion toCompanion(bool nullToAbsent) {
    return PeerContactsCompanion(
      nodeId: Value(nodeId),
      host: Value(host),
      port: Value(port),
      lastSeenMs: Value(lastSeenMs),
      seenCount: Value(seenCount),
    );
  }

  factory PeerContact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeerContact(
      nodeId: serializer.fromJson<String>(json['nodeId']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      lastSeenMs: serializer.fromJson<int>(json['lastSeenMs']),
      seenCount: serializer.fromJson<int>(json['seenCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeId': serializer.toJson<String>(nodeId),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'lastSeenMs': serializer.toJson<int>(lastSeenMs),
      'seenCount': serializer.toJson<int>(seenCount),
    };
  }

  PeerContact copyWith({
    String? nodeId,
    String? host,
    int? port,
    int? lastSeenMs,
    int? seenCount,
  }) => PeerContact(
    nodeId: nodeId ?? this.nodeId,
    host: host ?? this.host,
    port: port ?? this.port,
    lastSeenMs: lastSeenMs ?? this.lastSeenMs,
    seenCount: seenCount ?? this.seenCount,
  );
  PeerContact copyWithCompanion(PeerContactsCompanion data) {
    return PeerContact(
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      lastSeenMs: data.lastSeenMs.present
          ? data.lastSeenMs.value
          : this.lastSeenMs,
      seenCount: data.seenCount.present ? data.seenCount.value : this.seenCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeerContact(')
          ..write('nodeId: $nodeId, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('lastSeenMs: $lastSeenMs, ')
          ..write('seenCount: $seenCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(nodeId, host, port, lastSeenMs, seenCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeerContact &&
          other.nodeId == this.nodeId &&
          other.host == this.host &&
          other.port == this.port &&
          other.lastSeenMs == this.lastSeenMs &&
          other.seenCount == this.seenCount);
}

class PeerContactsCompanion extends UpdateCompanion<PeerContact> {
  final Value<String> nodeId;
  final Value<String> host;
  final Value<int> port;
  final Value<int> lastSeenMs;
  final Value<int> seenCount;
  final Value<int> rowid;
  const PeerContactsCompanion({
    this.nodeId = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.lastSeenMs = const Value.absent(),
    this.seenCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeerContactsCompanion.insert({
    required String nodeId,
    required String host,
    required int port,
    required int lastSeenMs,
    this.seenCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : nodeId = Value(nodeId),
       host = Value(host),
       port = Value(port),
       lastSeenMs = Value(lastSeenMs);
  static Insertable<PeerContact> custom({
    Expression<String>? nodeId,
    Expression<String>? host,
    Expression<int>? port,
    Expression<int>? lastSeenMs,
    Expression<int>? seenCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeId != null) 'node_id': nodeId,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (lastSeenMs != null) 'last_seen_ms': lastSeenMs,
      if (seenCount != null) 'seen_count': seenCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeerContactsCompanion copyWith({
    Value<String>? nodeId,
    Value<String>? host,
    Value<int>? port,
    Value<int>? lastSeenMs,
    Value<int>? seenCount,
    Value<int>? rowid,
  }) {
    return PeerContactsCompanion(
      nodeId: nodeId ?? this.nodeId,
      host: host ?? this.host,
      port: port ?? this.port,
      lastSeenMs: lastSeenMs ?? this.lastSeenMs,
      seenCount: seenCount ?? this.seenCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (lastSeenMs.present) {
      map['last_seen_ms'] = Variable<int>(lastSeenMs.value);
    }
    if (seenCount.present) {
      map['seen_count'] = Variable<int>(seenCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeerContactsCompanion(')
          ..write('nodeId: $nodeId, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('lastSeenMs: $lastSeenMs, ')
          ..write('seenCount: $seenCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncJobsTable extends SyncJobs with TableInfo<$SyncJobsTable, SyncJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMsMeta = const VerificationMeta(
    'completedAtMs',
  );
  @override
  late final GeneratedColumn<int> completedAtMs = GeneratedColumn<int>(
    'completed_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadedCountMeta = const VerificationMeta(
    'uploadedCount',
  );
  @override
  late final GeneratedColumn<int> uploadedCount = GeneratedColumn<int>(
    'uploaded_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _downloadedCountMeta = const VerificationMeta(
    'downloadedCount',
  );
  @override
  late final GeneratedColumn<int> downloadedCount = GeneratedColumn<int>(
    'downloaded_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _successMeta = const VerificationMeta(
    'success',
  );
  @override
  late final GeneratedColumn<bool> success = GeneratedColumn<bool>(
    'success',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("success" IN (0, 1))',
    ),
  );
  static const VerificationMeta _mockModeMeta = const VerificationMeta(
    'mockMode',
  );
  @override
  late final GeneratedColumn<bool> mockMode = GeneratedColumn<bool>(
    'mock_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mock_mode" IN (0, 1))',
    ),
  );
  static const VerificationMeta _gatewayEnabledMeta = const VerificationMeta(
    'gatewayEnabled',
  );
  @override
  late final GeneratedColumn<bool> gatewayEnabled = GeneratedColumn<bool>(
    'gateway_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gateway_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _internetReachableMeta = const VerificationMeta(
    'internetReachable',
  );
  @override
  late final GeneratedColumn<bool> internetReachable = GeneratedColumn<bool>(
    'internet_reachable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("internet_reachable" IN (0, 1))',
    ),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAtMs,
    completedAtMs,
    uploadedCount,
    downloadedCount,
    success,
    mockMode,
    gatewayEnabled,
    internetReachable,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('completed_at_ms')) {
      context.handle(
        _completedAtMsMeta,
        completedAtMs.isAcceptableOrUnknown(
          data['completed_at_ms']!,
          _completedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMsMeta);
    }
    if (data.containsKey('uploaded_count')) {
      context.handle(
        _uploadedCountMeta,
        uploadedCount.isAcceptableOrUnknown(
          data['uploaded_count']!,
          _uploadedCountMeta,
        ),
      );
    }
    if (data.containsKey('downloaded_count')) {
      context.handle(
        _downloadedCountMeta,
        downloadedCount.isAcceptableOrUnknown(
          data['downloaded_count']!,
          _downloadedCountMeta,
        ),
      );
    }
    if (data.containsKey('success')) {
      context.handle(
        _successMeta,
        success.isAcceptableOrUnknown(data['success']!, _successMeta),
      );
    } else if (isInserting) {
      context.missing(_successMeta);
    }
    if (data.containsKey('mock_mode')) {
      context.handle(
        _mockModeMeta,
        mockMode.isAcceptableOrUnknown(data['mock_mode']!, _mockModeMeta),
      );
    } else if (isInserting) {
      context.missing(_mockModeMeta);
    }
    if (data.containsKey('gateway_enabled')) {
      context.handle(
        _gatewayEnabledMeta,
        gatewayEnabled.isAcceptableOrUnknown(
          data['gateway_enabled']!,
          _gatewayEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gatewayEnabledMeta);
    }
    if (data.containsKey('internet_reachable')) {
      context.handle(
        _internetReachableMeta,
        internetReachable.isAcceptableOrUnknown(
          data['internet_reachable']!,
          _internetReachableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_internetReachableMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      completedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at_ms'],
      )!,
      uploadedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uploaded_count'],
      )!,
      downloadedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_count'],
      )!,
      success: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}success'],
      )!,
      mockMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mock_mode'],
      )!,
      gatewayEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gateway_enabled'],
      )!,
      internetReachable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}internet_reachable'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $SyncJobsTable createAlias(String alias) {
    return $SyncJobsTable(attachedDatabase, alias);
  }
}

class SyncJob extends DataClass implements Insertable<SyncJob> {
  final int id;
  final int startedAtMs;
  final int completedAtMs;
  final int uploadedCount;
  final int downloadedCount;
  final bool success;
  final bool mockMode;
  final bool gatewayEnabled;
  final bool internetReachable;
  final String? errorMessage;
  const SyncJob({
    required this.id,
    required this.startedAtMs,
    required this.completedAtMs,
    required this.uploadedCount,
    required this.downloadedCount,
    required this.success,
    required this.mockMode,
    required this.gatewayEnabled,
    required this.internetReachable,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at_ms'] = Variable<int>(startedAtMs);
    map['completed_at_ms'] = Variable<int>(completedAtMs);
    map['uploaded_count'] = Variable<int>(uploadedCount);
    map['downloaded_count'] = Variable<int>(downloadedCount);
    map['success'] = Variable<bool>(success);
    map['mock_mode'] = Variable<bool>(mockMode);
    map['gateway_enabled'] = Variable<bool>(gatewayEnabled);
    map['internet_reachable'] = Variable<bool>(internetReachable);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  SyncJobsCompanion toCompanion(bool nullToAbsent) {
    return SyncJobsCompanion(
      id: Value(id),
      startedAtMs: Value(startedAtMs),
      completedAtMs: Value(completedAtMs),
      uploadedCount: Value(uploadedCount),
      downloadedCount: Value(downloadedCount),
      success: Value(success),
      mockMode: Value(mockMode),
      gatewayEnabled: Value(gatewayEnabled),
      internetReachable: Value(internetReachable),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory SyncJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncJob(
      id: serializer.fromJson<int>(json['id']),
      startedAtMs: serializer.fromJson<int>(json['startedAtMs']),
      completedAtMs: serializer.fromJson<int>(json['completedAtMs']),
      uploadedCount: serializer.fromJson<int>(json['uploadedCount']),
      downloadedCount: serializer.fromJson<int>(json['downloadedCount']),
      success: serializer.fromJson<bool>(json['success']),
      mockMode: serializer.fromJson<bool>(json['mockMode']),
      gatewayEnabled: serializer.fromJson<bool>(json['gatewayEnabled']),
      internetReachable: serializer.fromJson<bool>(json['internetReachable']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAtMs': serializer.toJson<int>(startedAtMs),
      'completedAtMs': serializer.toJson<int>(completedAtMs),
      'uploadedCount': serializer.toJson<int>(uploadedCount),
      'downloadedCount': serializer.toJson<int>(downloadedCount),
      'success': serializer.toJson<bool>(success),
      'mockMode': serializer.toJson<bool>(mockMode),
      'gatewayEnabled': serializer.toJson<bool>(gatewayEnabled),
      'internetReachable': serializer.toJson<bool>(internetReachable),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  SyncJob copyWith({
    int? id,
    int? startedAtMs,
    int? completedAtMs,
    int? uploadedCount,
    int? downloadedCount,
    bool? success,
    bool? mockMode,
    bool? gatewayEnabled,
    bool? internetReachable,
    Value<String?> errorMessage = const Value.absent(),
  }) => SyncJob(
    id: id ?? this.id,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    completedAtMs: completedAtMs ?? this.completedAtMs,
    uploadedCount: uploadedCount ?? this.uploadedCount,
    downloadedCount: downloadedCount ?? this.downloadedCount,
    success: success ?? this.success,
    mockMode: mockMode ?? this.mockMode,
    gatewayEnabled: gatewayEnabled ?? this.gatewayEnabled,
    internetReachable: internetReachable ?? this.internetReachable,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  SyncJob copyWithCompanion(SyncJobsCompanion data) {
    return SyncJob(
      id: data.id.present ? data.id.value : this.id,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      completedAtMs: data.completedAtMs.present
          ? data.completedAtMs.value
          : this.completedAtMs,
      uploadedCount: data.uploadedCount.present
          ? data.uploadedCount.value
          : this.uploadedCount,
      downloadedCount: data.downloadedCount.present
          ? data.downloadedCount.value
          : this.downloadedCount,
      success: data.success.present ? data.success.value : this.success,
      mockMode: data.mockMode.present ? data.mockMode.value : this.mockMode,
      gatewayEnabled: data.gatewayEnabled.present
          ? data.gatewayEnabled.value
          : this.gatewayEnabled,
      internetReachable: data.internetReachable.present
          ? data.internetReachable.value
          : this.internetReachable,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncJob(')
          ..write('id: $id, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('uploadedCount: $uploadedCount, ')
          ..write('downloadedCount: $downloadedCount, ')
          ..write('success: $success, ')
          ..write('mockMode: $mockMode, ')
          ..write('gatewayEnabled: $gatewayEnabled, ')
          ..write('internetReachable: $internetReachable, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAtMs,
    completedAtMs,
    uploadedCount,
    downloadedCount,
    success,
    mockMode,
    gatewayEnabled,
    internetReachable,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncJob &&
          other.id == this.id &&
          other.startedAtMs == this.startedAtMs &&
          other.completedAtMs == this.completedAtMs &&
          other.uploadedCount == this.uploadedCount &&
          other.downloadedCount == this.downloadedCount &&
          other.success == this.success &&
          other.mockMode == this.mockMode &&
          other.gatewayEnabled == this.gatewayEnabled &&
          other.internetReachable == this.internetReachable &&
          other.errorMessage == this.errorMessage);
}

class SyncJobsCompanion extends UpdateCompanion<SyncJob> {
  final Value<int> id;
  final Value<int> startedAtMs;
  final Value<int> completedAtMs;
  final Value<int> uploadedCount;
  final Value<int> downloadedCount;
  final Value<bool> success;
  final Value<bool> mockMode;
  final Value<bool> gatewayEnabled;
  final Value<bool> internetReachable;
  final Value<String?> errorMessage;
  const SyncJobsCompanion({
    this.id = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.completedAtMs = const Value.absent(),
    this.uploadedCount = const Value.absent(),
    this.downloadedCount = const Value.absent(),
    this.success = const Value.absent(),
    this.mockMode = const Value.absent(),
    this.gatewayEnabled = const Value.absent(),
    this.internetReachable = const Value.absent(),
    this.errorMessage = const Value.absent(),
  });
  SyncJobsCompanion.insert({
    this.id = const Value.absent(),
    required int startedAtMs,
    required int completedAtMs,
    this.uploadedCount = const Value.absent(),
    this.downloadedCount = const Value.absent(),
    required bool success,
    required bool mockMode,
    required bool gatewayEnabled,
    required bool internetReachable,
    this.errorMessage = const Value.absent(),
  }) : startedAtMs = Value(startedAtMs),
       completedAtMs = Value(completedAtMs),
       success = Value(success),
       mockMode = Value(mockMode),
       gatewayEnabled = Value(gatewayEnabled),
       internetReachable = Value(internetReachable);
  static Insertable<SyncJob> custom({
    Expression<int>? id,
    Expression<int>? startedAtMs,
    Expression<int>? completedAtMs,
    Expression<int>? uploadedCount,
    Expression<int>? downloadedCount,
    Expression<bool>? success,
    Expression<bool>? mockMode,
    Expression<bool>? gatewayEnabled,
    Expression<bool>? internetReachable,
    Expression<String>? errorMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (completedAtMs != null) 'completed_at_ms': completedAtMs,
      if (uploadedCount != null) 'uploaded_count': uploadedCount,
      if (downloadedCount != null) 'downloaded_count': downloadedCount,
      if (success != null) 'success': success,
      if (mockMode != null) 'mock_mode': mockMode,
      if (gatewayEnabled != null) 'gateway_enabled': gatewayEnabled,
      if (internetReachable != null) 'internet_reachable': internetReachable,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  SyncJobsCompanion copyWith({
    Value<int>? id,
    Value<int>? startedAtMs,
    Value<int>? completedAtMs,
    Value<int>? uploadedCount,
    Value<int>? downloadedCount,
    Value<bool>? success,
    Value<bool>? mockMode,
    Value<bool>? gatewayEnabled,
    Value<bool>? internetReachable,
    Value<String?>? errorMessage,
  }) {
    return SyncJobsCompanion(
      id: id ?? this.id,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      completedAtMs: completedAtMs ?? this.completedAtMs,
      uploadedCount: uploadedCount ?? this.uploadedCount,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      success: success ?? this.success,
      mockMode: mockMode ?? this.mockMode,
      gatewayEnabled: gatewayEnabled ?? this.gatewayEnabled,
      internetReachable: internetReachable ?? this.internetReachable,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (completedAtMs.present) {
      map['completed_at_ms'] = Variable<int>(completedAtMs.value);
    }
    if (uploadedCount.present) {
      map['uploaded_count'] = Variable<int>(uploadedCount.value);
    }
    if (downloadedCount.present) {
      map['downloaded_count'] = Variable<int>(downloadedCount.value);
    }
    if (success.present) {
      map['success'] = Variable<bool>(success.value);
    }
    if (mockMode.present) {
      map['mock_mode'] = Variable<bool>(mockMode.value);
    }
    if (gatewayEnabled.present) {
      map['gateway_enabled'] = Variable<bool>(gatewayEnabled.value);
    }
    if (internetReachable.present) {
      map['internet_reachable'] = Variable<bool>(internetReachable.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncJobsCompanion(')
          ..write('id: $id, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('uploadedCount: $uploadedCount, ')
          ..write('downloadedCount: $downloadedCount, ')
          ..write('success: $success, ')
          ..write('mockMode: $mockMode, ')
          ..write('gatewayEnabled: $gatewayEnabled, ')
          ..write('internetReachable: $internetReachable, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }
}

class $MessageProjectionsTable extends MessageProjections
    with TableInfo<$MessageProjectionsTable, MessageProjection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageProjectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bundleIdMeta = const VerificationMeta(
    'bundleId',
  );
  @override
  late final GeneratedColumn<String> bundleId = GeneratedColumn<String>(
    'bundle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNodeIdMeta = const VerificationMeta(
    'sourceNodeId',
  );
  @override
  late final GeneratedColumn<String> sourceNodeId = GeneratedColumn<String>(
    'source_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationNodeIdMeta = const VerificationMeta(
    'destinationNodeId',
  );
  @override
  late final GeneratedColumn<String> destinationNodeId =
      GeneratedColumn<String>(
        'destination_node_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isOutgoingMeta = const VerificationMeta(
    'isOutgoing',
  );
  @override
  late final GeneratedColumn<bool> isOutgoing = GeneratedColumn<bool>(
    'is_outgoing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_outgoing" IN (0, 1))',
    ),
  );
  static const VerificationMeta _deliveryStatusMeta = const VerificationMeta(
    'deliveryStatus',
  );
  @override
  late final GeneratedColumn<String> deliveryStatus = GeneratedColumn<String>(
    'delivery_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failedAttemptsMeta = const VerificationMeta(
    'failedAttempts',
  );
  @override
  late final GeneratedColumn<int> failedAttempts = GeneratedColumn<int>(
    'failed_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bundleId,
    sourceNodeId,
    destinationNodeId,
    body,
    createdAtMs,
    isOutgoing,
    deliveryStatus,
    failedAttempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_projections';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageProjection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bundle_id')) {
      context.handle(
        _bundleIdMeta,
        bundleId.isAcceptableOrUnknown(data['bundle_id']!, _bundleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bundleIdMeta);
    }
    if (data.containsKey('source_node_id')) {
      context.handle(
        _sourceNodeIdMeta,
        sourceNodeId.isAcceptableOrUnknown(
          data['source_node_id']!,
          _sourceNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceNodeIdMeta);
    }
    if (data.containsKey('destination_node_id')) {
      context.handle(
        _destinationNodeIdMeta,
        destinationNodeId.isAcceptableOrUnknown(
          data['destination_node_id']!,
          _destinationNodeIdMeta,
        ),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('is_outgoing')) {
      context.handle(
        _isOutgoingMeta,
        isOutgoing.isAcceptableOrUnknown(data['is_outgoing']!, _isOutgoingMeta),
      );
    } else if (isInserting) {
      context.missing(_isOutgoingMeta);
    }
    if (data.containsKey('delivery_status')) {
      context.handle(
        _deliveryStatusMeta,
        deliveryStatus.isAcceptableOrUnknown(
          data['delivery_status']!,
          _deliveryStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryStatusMeta);
    }
    if (data.containsKey('failed_attempts')) {
      context.handle(
        _failedAttemptsMeta,
        failedAttempts.isAcceptableOrUnknown(
          data['failed_attempts']!,
          _failedAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bundleId};
  @override
  MessageProjection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageProjection(
      bundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bundle_id'],
      )!,
      sourceNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_node_id'],
      )!,
      destinationNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_node_id'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      isOutgoing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_outgoing'],
      )!,
      deliveryStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_status'],
      )!,
      failedAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $MessageProjectionsTable createAlias(String alias) {
    return $MessageProjectionsTable(attachedDatabase, alias);
  }
}

class MessageProjection extends DataClass
    implements Insertable<MessageProjection> {
  final String bundleId;
  final String sourceNodeId;
  final String? destinationNodeId;
  final String body;
  final int createdAtMs;
  final bool isOutgoing;
  final String deliveryStatus;
  final int failedAttempts;
  final String? lastError;
  const MessageProjection({
    required this.bundleId,
    required this.sourceNodeId,
    this.destinationNodeId,
    required this.body,
    required this.createdAtMs,
    required this.isOutgoing,
    required this.deliveryStatus,
    required this.failedAttempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bundle_id'] = Variable<String>(bundleId);
    map['source_node_id'] = Variable<String>(sourceNodeId);
    if (!nullToAbsent || destinationNodeId != null) {
      map['destination_node_id'] = Variable<String>(destinationNodeId);
    }
    map['body'] = Variable<String>(body);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['is_outgoing'] = Variable<bool>(isOutgoing);
    map['delivery_status'] = Variable<String>(deliveryStatus);
    map['failed_attempts'] = Variable<int>(failedAttempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  MessageProjectionsCompanion toCompanion(bool nullToAbsent) {
    return MessageProjectionsCompanion(
      bundleId: Value(bundleId),
      sourceNodeId: Value(sourceNodeId),
      destinationNodeId: destinationNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationNodeId),
      body: Value(body),
      createdAtMs: Value(createdAtMs),
      isOutgoing: Value(isOutgoing),
      deliveryStatus: Value(deliveryStatus),
      failedAttempts: Value(failedAttempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory MessageProjection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageProjection(
      bundleId: serializer.fromJson<String>(json['bundleId']),
      sourceNodeId: serializer.fromJson<String>(json['sourceNodeId']),
      destinationNodeId: serializer.fromJson<String?>(
        json['destinationNodeId'],
      ),
      body: serializer.fromJson<String>(json['body']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      isOutgoing: serializer.fromJson<bool>(json['isOutgoing']),
      deliveryStatus: serializer.fromJson<String>(json['deliveryStatus']),
      failedAttempts: serializer.fromJson<int>(json['failedAttempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bundleId': serializer.toJson<String>(bundleId),
      'sourceNodeId': serializer.toJson<String>(sourceNodeId),
      'destinationNodeId': serializer.toJson<String?>(destinationNodeId),
      'body': serializer.toJson<String>(body),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'isOutgoing': serializer.toJson<bool>(isOutgoing),
      'deliveryStatus': serializer.toJson<String>(deliveryStatus),
      'failedAttempts': serializer.toJson<int>(failedAttempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  MessageProjection copyWith({
    String? bundleId,
    String? sourceNodeId,
    Value<String?> destinationNodeId = const Value.absent(),
    String? body,
    int? createdAtMs,
    bool? isOutgoing,
    String? deliveryStatus,
    int? failedAttempts,
    Value<String?> lastError = const Value.absent(),
  }) => MessageProjection(
    bundleId: bundleId ?? this.bundleId,
    sourceNodeId: sourceNodeId ?? this.sourceNodeId,
    destinationNodeId: destinationNodeId.present
        ? destinationNodeId.value
        : this.destinationNodeId,
    body: body ?? this.body,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    isOutgoing: isOutgoing ?? this.isOutgoing,
    deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  MessageProjection copyWithCompanion(MessageProjectionsCompanion data) {
    return MessageProjection(
      bundleId: data.bundleId.present ? data.bundleId.value : this.bundleId,
      sourceNodeId: data.sourceNodeId.present
          ? data.sourceNodeId.value
          : this.sourceNodeId,
      destinationNodeId: data.destinationNodeId.present
          ? data.destinationNodeId.value
          : this.destinationNodeId,
      body: data.body.present ? data.body.value : this.body,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      isOutgoing: data.isOutgoing.present
          ? data.isOutgoing.value
          : this.isOutgoing,
      deliveryStatus: data.deliveryStatus.present
          ? data.deliveryStatus.value
          : this.deliveryStatus,
      failedAttempts: data.failedAttempts.present
          ? data.failedAttempts.value
          : this.failedAttempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageProjection(')
          ..write('bundleId: $bundleId, ')
          ..write('sourceNodeId: $sourceNodeId, ')
          ..write('destinationNodeId: $destinationNodeId, ')
          ..write('body: $body, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bundleId,
    sourceNodeId,
    destinationNodeId,
    body,
    createdAtMs,
    isOutgoing,
    deliveryStatus,
    failedAttempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageProjection &&
          other.bundleId == this.bundleId &&
          other.sourceNodeId == this.sourceNodeId &&
          other.destinationNodeId == this.destinationNodeId &&
          other.body == this.body &&
          other.createdAtMs == this.createdAtMs &&
          other.isOutgoing == this.isOutgoing &&
          other.deliveryStatus == this.deliveryStatus &&
          other.failedAttempts == this.failedAttempts &&
          other.lastError == this.lastError);
}

class MessageProjectionsCompanion extends UpdateCompanion<MessageProjection> {
  final Value<String> bundleId;
  final Value<String> sourceNodeId;
  final Value<String?> destinationNodeId;
  final Value<String> body;
  final Value<int> createdAtMs;
  final Value<bool> isOutgoing;
  final Value<String> deliveryStatus;
  final Value<int> failedAttempts;
  final Value<String?> lastError;
  final Value<int> rowid;
  const MessageProjectionsCompanion({
    this.bundleId = const Value.absent(),
    this.sourceNodeId = const Value.absent(),
    this.destinationNodeId = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.isOutgoing = const Value.absent(),
    this.deliveryStatus = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageProjectionsCompanion.insert({
    required String bundleId,
    required String sourceNodeId,
    this.destinationNodeId = const Value.absent(),
    required String body,
    required int createdAtMs,
    required bool isOutgoing,
    required String deliveryStatus,
    this.failedAttempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bundleId = Value(bundleId),
       sourceNodeId = Value(sourceNodeId),
       body = Value(body),
       createdAtMs = Value(createdAtMs),
       isOutgoing = Value(isOutgoing),
       deliveryStatus = Value(deliveryStatus);
  static Insertable<MessageProjection> custom({
    Expression<String>? bundleId,
    Expression<String>? sourceNodeId,
    Expression<String>? destinationNodeId,
    Expression<String>? body,
    Expression<int>? createdAtMs,
    Expression<bool>? isOutgoing,
    Expression<String>? deliveryStatus,
    Expression<int>? failedAttempts,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bundleId != null) 'bundle_id': bundleId,
      if (sourceNodeId != null) 'source_node_id': sourceNodeId,
      if (destinationNodeId != null) 'destination_node_id': destinationNodeId,
      if (body != null) 'body': body,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (isOutgoing != null) 'is_outgoing': isOutgoing,
      if (deliveryStatus != null) 'delivery_status': deliveryStatus,
      if (failedAttempts != null) 'failed_attempts': failedAttempts,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageProjectionsCompanion copyWith({
    Value<String>? bundleId,
    Value<String>? sourceNodeId,
    Value<String?>? destinationNodeId,
    Value<String>? body,
    Value<int>? createdAtMs,
    Value<bool>? isOutgoing,
    Value<String>? deliveryStatus,
    Value<int>? failedAttempts,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return MessageProjectionsCompanion(
      bundleId: bundleId ?? this.bundleId,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      destinationNodeId: destinationNodeId ?? this.destinationNodeId,
      body: body ?? this.body,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bundleId.present) {
      map['bundle_id'] = Variable<String>(bundleId.value);
    }
    if (sourceNodeId.present) {
      map['source_node_id'] = Variable<String>(sourceNodeId.value);
    }
    if (destinationNodeId.present) {
      map['destination_node_id'] = Variable<String>(destinationNodeId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (isOutgoing.present) {
      map['is_outgoing'] = Variable<bool>(isOutgoing.value);
    }
    if (deliveryStatus.present) {
      map['delivery_status'] = Variable<String>(deliveryStatus.value);
    }
    if (failedAttempts.present) {
      map['failed_attempts'] = Variable<int>(failedAttempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageProjectionsCompanion(')
          ..write('bundleId: $bundleId, ')
          ..write('sourceNodeId: $sourceNodeId, ')
          ..write('destinationNodeId: $destinationNodeId, ')
          ..write('body: $body, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AckEventsTable extends AckEvents
    with TableInfo<$AckEventsTable, AckEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AckEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ackBundleIdMeta = const VerificationMeta(
    'ackBundleId',
  );
  @override
  late final GeneratedColumn<String> ackBundleId = GeneratedColumn<String>(
    'ack_bundle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ackForBundleIdMeta = const VerificationMeta(
    'ackForBundleId',
  );
  @override
  late final GeneratedColumn<String> ackForBundleId = GeneratedColumn<String>(
    'ack_for_bundle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceNodeIdMeta = const VerificationMeta(
    'sourceNodeId',
  );
  @override
  late final GeneratedColumn<String> sourceNodeId = GeneratedColumn<String>(
    'source_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstReceivedAtMsMeta = const VerificationMeta(
    'firstReceivedAtMs',
  );
  @override
  late final GeneratedColumn<int> firstReceivedAtMs = GeneratedColumn<int>(
    'first_received_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReceivedAtMsMeta = const VerificationMeta(
    'lastReceivedAtMs',
  );
  @override
  late final GeneratedColumn<int> lastReceivedAtMs = GeneratedColumn<int>(
    'last_received_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _duplicateCountMeta = const VerificationMeta(
    'duplicateCount',
  );
  @override
  late final GeneratedColumn<int> duplicateCount = GeneratedColumn<int>(
    'duplicate_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    ackBundleId,
    ackForBundleId,
    sourceNodeId,
    firstReceivedAtMs,
    lastReceivedAtMs,
    duplicateCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ack_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<AckEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ack_bundle_id')) {
      context.handle(
        _ackBundleIdMeta,
        ackBundleId.isAcceptableOrUnknown(
          data['ack_bundle_id']!,
          _ackBundleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ackBundleIdMeta);
    }
    if (data.containsKey('ack_for_bundle_id')) {
      context.handle(
        _ackForBundleIdMeta,
        ackForBundleId.isAcceptableOrUnknown(
          data['ack_for_bundle_id']!,
          _ackForBundleIdMeta,
        ),
      );
    }
    if (data.containsKey('source_node_id')) {
      context.handle(
        _sourceNodeIdMeta,
        sourceNodeId.isAcceptableOrUnknown(
          data['source_node_id']!,
          _sourceNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceNodeIdMeta);
    }
    if (data.containsKey('first_received_at_ms')) {
      context.handle(
        _firstReceivedAtMsMeta,
        firstReceivedAtMs.isAcceptableOrUnknown(
          data['first_received_at_ms']!,
          _firstReceivedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstReceivedAtMsMeta);
    }
    if (data.containsKey('last_received_at_ms')) {
      context.handle(
        _lastReceivedAtMsMeta,
        lastReceivedAtMs.isAcceptableOrUnknown(
          data['last_received_at_ms']!,
          _lastReceivedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastReceivedAtMsMeta);
    }
    if (data.containsKey('duplicate_count')) {
      context.handle(
        _duplicateCountMeta,
        duplicateCount.isAcceptableOrUnknown(
          data['duplicate_count']!,
          _duplicateCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ackBundleId};
  @override
  AckEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AckEvent(
      ackBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ack_bundle_id'],
      )!,
      ackForBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ack_for_bundle_id'],
      ),
      sourceNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_node_id'],
      )!,
      firstReceivedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_received_at_ms'],
      )!,
      lastReceivedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_received_at_ms'],
      )!,
      duplicateCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duplicate_count'],
      )!,
    );
  }

  @override
  $AckEventsTable createAlias(String alias) {
    return $AckEventsTable(attachedDatabase, alias);
  }
}

class AckEvent extends DataClass implements Insertable<AckEvent> {
  final String ackBundleId;
  final String? ackForBundleId;
  final String sourceNodeId;
  final int firstReceivedAtMs;
  final int lastReceivedAtMs;
  final int duplicateCount;
  const AckEvent({
    required this.ackBundleId,
    this.ackForBundleId,
    required this.sourceNodeId,
    required this.firstReceivedAtMs,
    required this.lastReceivedAtMs,
    required this.duplicateCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ack_bundle_id'] = Variable<String>(ackBundleId);
    if (!nullToAbsent || ackForBundleId != null) {
      map['ack_for_bundle_id'] = Variable<String>(ackForBundleId);
    }
    map['source_node_id'] = Variable<String>(sourceNodeId);
    map['first_received_at_ms'] = Variable<int>(firstReceivedAtMs);
    map['last_received_at_ms'] = Variable<int>(lastReceivedAtMs);
    map['duplicate_count'] = Variable<int>(duplicateCount);
    return map;
  }

  AckEventsCompanion toCompanion(bool nullToAbsent) {
    return AckEventsCompanion(
      ackBundleId: Value(ackBundleId),
      ackForBundleId: ackForBundleId == null && nullToAbsent
          ? const Value.absent()
          : Value(ackForBundleId),
      sourceNodeId: Value(sourceNodeId),
      firstReceivedAtMs: Value(firstReceivedAtMs),
      lastReceivedAtMs: Value(lastReceivedAtMs),
      duplicateCount: Value(duplicateCount),
    );
  }

  factory AckEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AckEvent(
      ackBundleId: serializer.fromJson<String>(json['ackBundleId']),
      ackForBundleId: serializer.fromJson<String?>(json['ackForBundleId']),
      sourceNodeId: serializer.fromJson<String>(json['sourceNodeId']),
      firstReceivedAtMs: serializer.fromJson<int>(json['firstReceivedAtMs']),
      lastReceivedAtMs: serializer.fromJson<int>(json['lastReceivedAtMs']),
      duplicateCount: serializer.fromJson<int>(json['duplicateCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ackBundleId': serializer.toJson<String>(ackBundleId),
      'ackForBundleId': serializer.toJson<String?>(ackForBundleId),
      'sourceNodeId': serializer.toJson<String>(sourceNodeId),
      'firstReceivedAtMs': serializer.toJson<int>(firstReceivedAtMs),
      'lastReceivedAtMs': serializer.toJson<int>(lastReceivedAtMs),
      'duplicateCount': serializer.toJson<int>(duplicateCount),
    };
  }

  AckEvent copyWith({
    String? ackBundleId,
    Value<String?> ackForBundleId = const Value.absent(),
    String? sourceNodeId,
    int? firstReceivedAtMs,
    int? lastReceivedAtMs,
    int? duplicateCount,
  }) => AckEvent(
    ackBundleId: ackBundleId ?? this.ackBundleId,
    ackForBundleId: ackForBundleId.present
        ? ackForBundleId.value
        : this.ackForBundleId,
    sourceNodeId: sourceNodeId ?? this.sourceNodeId,
    firstReceivedAtMs: firstReceivedAtMs ?? this.firstReceivedAtMs,
    lastReceivedAtMs: lastReceivedAtMs ?? this.lastReceivedAtMs,
    duplicateCount: duplicateCount ?? this.duplicateCount,
  );
  AckEvent copyWithCompanion(AckEventsCompanion data) {
    return AckEvent(
      ackBundleId: data.ackBundleId.present
          ? data.ackBundleId.value
          : this.ackBundleId,
      ackForBundleId: data.ackForBundleId.present
          ? data.ackForBundleId.value
          : this.ackForBundleId,
      sourceNodeId: data.sourceNodeId.present
          ? data.sourceNodeId.value
          : this.sourceNodeId,
      firstReceivedAtMs: data.firstReceivedAtMs.present
          ? data.firstReceivedAtMs.value
          : this.firstReceivedAtMs,
      lastReceivedAtMs: data.lastReceivedAtMs.present
          ? data.lastReceivedAtMs.value
          : this.lastReceivedAtMs,
      duplicateCount: data.duplicateCount.present
          ? data.duplicateCount.value
          : this.duplicateCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AckEvent(')
          ..write('ackBundleId: $ackBundleId, ')
          ..write('ackForBundleId: $ackForBundleId, ')
          ..write('sourceNodeId: $sourceNodeId, ')
          ..write('firstReceivedAtMs: $firstReceivedAtMs, ')
          ..write('lastReceivedAtMs: $lastReceivedAtMs, ')
          ..write('duplicateCount: $duplicateCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ackBundleId,
    ackForBundleId,
    sourceNodeId,
    firstReceivedAtMs,
    lastReceivedAtMs,
    duplicateCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AckEvent &&
          other.ackBundleId == this.ackBundleId &&
          other.ackForBundleId == this.ackForBundleId &&
          other.sourceNodeId == this.sourceNodeId &&
          other.firstReceivedAtMs == this.firstReceivedAtMs &&
          other.lastReceivedAtMs == this.lastReceivedAtMs &&
          other.duplicateCount == this.duplicateCount);
}

class AckEventsCompanion extends UpdateCompanion<AckEvent> {
  final Value<String> ackBundleId;
  final Value<String?> ackForBundleId;
  final Value<String> sourceNodeId;
  final Value<int> firstReceivedAtMs;
  final Value<int> lastReceivedAtMs;
  final Value<int> duplicateCount;
  final Value<int> rowid;
  const AckEventsCompanion({
    this.ackBundleId = const Value.absent(),
    this.ackForBundleId = const Value.absent(),
    this.sourceNodeId = const Value.absent(),
    this.firstReceivedAtMs = const Value.absent(),
    this.lastReceivedAtMs = const Value.absent(),
    this.duplicateCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AckEventsCompanion.insert({
    required String ackBundleId,
    this.ackForBundleId = const Value.absent(),
    required String sourceNodeId,
    required int firstReceivedAtMs,
    required int lastReceivedAtMs,
    this.duplicateCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ackBundleId = Value(ackBundleId),
       sourceNodeId = Value(sourceNodeId),
       firstReceivedAtMs = Value(firstReceivedAtMs),
       lastReceivedAtMs = Value(lastReceivedAtMs);
  static Insertable<AckEvent> custom({
    Expression<String>? ackBundleId,
    Expression<String>? ackForBundleId,
    Expression<String>? sourceNodeId,
    Expression<int>? firstReceivedAtMs,
    Expression<int>? lastReceivedAtMs,
    Expression<int>? duplicateCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ackBundleId != null) 'ack_bundle_id': ackBundleId,
      if (ackForBundleId != null) 'ack_for_bundle_id': ackForBundleId,
      if (sourceNodeId != null) 'source_node_id': sourceNodeId,
      if (firstReceivedAtMs != null) 'first_received_at_ms': firstReceivedAtMs,
      if (lastReceivedAtMs != null) 'last_received_at_ms': lastReceivedAtMs,
      if (duplicateCount != null) 'duplicate_count': duplicateCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AckEventsCompanion copyWith({
    Value<String>? ackBundleId,
    Value<String?>? ackForBundleId,
    Value<String>? sourceNodeId,
    Value<int>? firstReceivedAtMs,
    Value<int>? lastReceivedAtMs,
    Value<int>? duplicateCount,
    Value<int>? rowid,
  }) {
    return AckEventsCompanion(
      ackBundleId: ackBundleId ?? this.ackBundleId,
      ackForBundleId: ackForBundleId ?? this.ackForBundleId,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      firstReceivedAtMs: firstReceivedAtMs ?? this.firstReceivedAtMs,
      lastReceivedAtMs: lastReceivedAtMs ?? this.lastReceivedAtMs,
      duplicateCount: duplicateCount ?? this.duplicateCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ackBundleId.present) {
      map['ack_bundle_id'] = Variable<String>(ackBundleId.value);
    }
    if (ackForBundleId.present) {
      map['ack_for_bundle_id'] = Variable<String>(ackForBundleId.value);
    }
    if (sourceNodeId.present) {
      map['source_node_id'] = Variable<String>(sourceNodeId.value);
    }
    if (firstReceivedAtMs.present) {
      map['first_received_at_ms'] = Variable<int>(firstReceivedAtMs.value);
    }
    if (lastReceivedAtMs.present) {
      map['last_received_at_ms'] = Variable<int>(lastReceivedAtMs.value);
    }
    if (duplicateCount.present) {
      map['duplicate_count'] = Variable<int>(duplicateCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AckEventsCompanion(')
          ..write('ackBundleId: $ackBundleId, ')
          ..write('ackForBundleId: $ackForBundleId, ')
          ..write('sourceNodeId: $sourceNodeId, ')
          ..write('firstReceivedAtMs: $firstReceivedAtMs, ')
          ..write('lastReceivedAtMs: $lastReceivedAtMs, ')
          ..write('duplicateCount: $duplicateCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentMetadataTable extends ContentMetadata
    with TableInfo<$ContentMetadataTable, ContentMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkCountMeta = const VerificationMeta(
    'chunkCount',
  );
  @override
  late final GeneratedColumn<int> chunkCount = GeneratedColumn<int>(
    'chunk_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    contentHash,
    mimeType,
    totalBytes,
    chunkCount,
    createdAtMs,
    localPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
    }
    if (data.containsKey('chunk_count')) {
      context.handle(
        _chunkCountMeta,
        chunkCount.isAcceptableOrUnknown(data['chunk_count']!, _chunkCountMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contentHash};
  @override
  ContentMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentMetadataData(
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      chunkCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_count'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
    );
  }

  @override
  $ContentMetadataTable createAlias(String alias) {
    return $ContentMetadataTable(attachedDatabase, alias);
  }
}

class ContentMetadataData extends DataClass
    implements Insertable<ContentMetadataData> {
  final String contentHash;
  final String? mimeType;
  final int totalBytes;
  final int chunkCount;
  final int createdAtMs;
  final String? localPath;
  const ContentMetadataData({
    required this.contentHash,
    this.mimeType,
    required this.totalBytes,
    required this.chunkCount,
    required this.createdAtMs,
    this.localPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_hash'] = Variable<String>(contentHash);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    map['total_bytes'] = Variable<int>(totalBytes);
    map['chunk_count'] = Variable<int>(chunkCount);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    return map;
  }

  ContentMetadataCompanion toCompanion(bool nullToAbsent) {
    return ContentMetadataCompanion(
      contentHash: Value(contentHash),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      totalBytes: Value(totalBytes),
      chunkCount: Value(chunkCount),
      createdAtMs: Value(createdAtMs),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
    );
  }

  factory ContentMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentMetadataData(
      contentHash: serializer.fromJson<String>(json['contentHash']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      chunkCount: serializer.fromJson<int>(json['chunkCount']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      localPath: serializer.fromJson<String?>(json['localPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentHash': serializer.toJson<String>(contentHash),
      'mimeType': serializer.toJson<String?>(mimeType),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'chunkCount': serializer.toJson<int>(chunkCount),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'localPath': serializer.toJson<String?>(localPath),
    };
  }

  ContentMetadataData copyWith({
    String? contentHash,
    Value<String?> mimeType = const Value.absent(),
    int? totalBytes,
    int? chunkCount,
    int? createdAtMs,
    Value<String?> localPath = const Value.absent(),
  }) => ContentMetadataData(
    contentHash: contentHash ?? this.contentHash,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    totalBytes: totalBytes ?? this.totalBytes,
    chunkCount: chunkCount ?? this.chunkCount,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    localPath: localPath.present ? localPath.value : this.localPath,
  );
  ContentMetadataData copyWithCompanion(ContentMetadataCompanion data) {
    return ContentMetadataData(
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      chunkCount: data.chunkCount.present
          ? data.chunkCount.value
          : this.chunkCount,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentMetadataData(')
          ..write('contentHash: $contentHash, ')
          ..write('mimeType: $mimeType, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('chunkCount: $chunkCount, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('localPath: $localPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contentHash,
    mimeType,
    totalBytes,
    chunkCount,
    createdAtMs,
    localPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentMetadataData &&
          other.contentHash == this.contentHash &&
          other.mimeType == this.mimeType &&
          other.totalBytes == this.totalBytes &&
          other.chunkCount == this.chunkCount &&
          other.createdAtMs == this.createdAtMs &&
          other.localPath == this.localPath);
}

class ContentMetadataCompanion extends UpdateCompanion<ContentMetadataData> {
  final Value<String> contentHash;
  final Value<String?> mimeType;
  final Value<int> totalBytes;
  final Value<int> chunkCount;
  final Value<int> createdAtMs;
  final Value<String?> localPath;
  final Value<int> rowid;
  const ContentMetadataCompanion({
    this.contentHash = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.chunkCount = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.localPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentMetadataCompanion.insert({
    required String contentHash,
    this.mimeType = const Value.absent(),
    required int totalBytes,
    this.chunkCount = const Value.absent(),
    required int createdAtMs,
    this.localPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : contentHash = Value(contentHash),
       totalBytes = Value(totalBytes),
       createdAtMs = Value(createdAtMs);
  static Insertable<ContentMetadataData> custom({
    Expression<String>? contentHash,
    Expression<String>? mimeType,
    Expression<int>? totalBytes,
    Expression<int>? chunkCount,
    Expression<int>? createdAtMs,
    Expression<String>? localPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentHash != null) 'content_hash': contentHash,
      if (mimeType != null) 'mime_type': mimeType,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (chunkCount != null) 'chunk_count': chunkCount,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (localPath != null) 'local_path': localPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentMetadataCompanion copyWith({
    Value<String>? contentHash,
    Value<String?>? mimeType,
    Value<int>? totalBytes,
    Value<int>? chunkCount,
    Value<int>? createdAtMs,
    Value<String?>? localPath,
    Value<int>? rowid,
  }) {
    return ContentMetadataCompanion(
      contentHash: contentHash ?? this.contentHash,
      mimeType: mimeType ?? this.mimeType,
      totalBytes: totalBytes ?? this.totalBytes,
      chunkCount: chunkCount ?? this.chunkCount,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      localPath: localPath ?? this.localPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (chunkCount.present) {
      map['chunk_count'] = Variable<int>(chunkCount.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentMetadataCompanion(')
          ..write('contentHash: $contentHash, ')
          ..write('mimeType: $mimeType, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('chunkCount: $chunkCount, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('localPath: $localPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BundleRecordsTable bundleRecords = $BundleRecordsTable(this);
  late final $PeerContactsTable peerContacts = $PeerContactsTable(this);
  late final $SyncJobsTable syncJobs = $SyncJobsTable(this);
  late final $MessageProjectionsTable messageProjections =
      $MessageProjectionsTable(this);
  late final $AckEventsTable ackEvents = $AckEventsTable(this);
  late final $ContentMetadataTable contentMetadata = $ContentMetadataTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bundleRecords,
    peerContacts,
    syncJobs,
    messageProjections,
    ackEvents,
    contentMetadata,
  ];
}

typedef $$BundleRecordsTableCreateCompanionBuilder =
    BundleRecordsCompanion Function({
      required String bundleId,
      required String type,
      required String sourceNodeId,
      Value<String?> destinationNodeId,
      Value<String> destinationScope,
      Value<String> priority,
      Value<String?> ackForBundleId,
      Value<String?> payload,
      Value<String?> payloadRef,
      Value<String?> signature,
      Value<String> appId,
      required int createdAtMs,
      Value<int?> expiresAtMs,
      required int ttlSeconds,
      Value<int> hopCount,
      Value<bool> acknowledged,
      Value<int?> sentAtMs,
      Value<int> failedAttempts,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$BundleRecordsTableUpdateCompanionBuilder =
    BundleRecordsCompanion Function({
      Value<String> bundleId,
      Value<String> type,
      Value<String> sourceNodeId,
      Value<String?> destinationNodeId,
      Value<String> destinationScope,
      Value<String> priority,
      Value<String?> ackForBundleId,
      Value<String?> payload,
      Value<String?> payloadRef,
      Value<String?> signature,
      Value<String> appId,
      Value<int> createdAtMs,
      Value<int?> expiresAtMs,
      Value<int> ttlSeconds,
      Value<int> hopCount,
      Value<bool> acknowledged,
      Value<int?> sentAtMs,
      Value<int> failedAttempts,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$BundleRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $BundleRecordsTable> {
  $$BundleRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bundleId => $composableBuilder(
    column: $table.bundleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationNodeId => $composableBuilder(
    column: $table.destinationNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationScope => $composableBuilder(
    column: $table.destinationScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ackForBundleId => $composableBuilder(
    column: $table.ackForBundleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadRef => $composableBuilder(
    column: $table.payloadRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hopCount => $composableBuilder(
    column: $table.hopCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentAtMs => $composableBuilder(
    column: $table.sentAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BundleRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $BundleRecordsTable> {
  $$BundleRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bundleId => $composableBuilder(
    column: $table.bundleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationNodeId => $composableBuilder(
    column: $table.destinationNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationScope => $composableBuilder(
    column: $table.destinationScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ackForBundleId => $composableBuilder(
    column: $table.ackForBundleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadRef => $composableBuilder(
    column: $table.payloadRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hopCount => $composableBuilder(
    column: $table.hopCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentAtMs => $composableBuilder(
    column: $table.sentAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BundleRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BundleRecordsTable> {
  $$BundleRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bundleId =>
      $composableBuilder(column: $table.bundleId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationNodeId => $composableBuilder(
    column: $table.destinationNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationScope => $composableBuilder(
    column: $table.destinationScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get ackForBundleId => $composableBuilder(
    column: $table.ackForBundleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get payloadRef => $composableBuilder(
    column: $table.payloadRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<String> get appId =>
      $composableBuilder(column: $table.appId, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hopCount =>
      $composableBuilder(column: $table.hopCount, builder: (column) => column);

  GeneratedColumn<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sentAtMs =>
      $composableBuilder(column: $table.sentAtMs, builder: (column) => column);

  GeneratedColumn<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$BundleRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BundleRecordsTable,
          BundleRecord,
          $$BundleRecordsTableFilterComposer,
          $$BundleRecordsTableOrderingComposer,
          $$BundleRecordsTableAnnotationComposer,
          $$BundleRecordsTableCreateCompanionBuilder,
          $$BundleRecordsTableUpdateCompanionBuilder,
          (
            BundleRecord,
            BaseReferences<_$AppDatabase, $BundleRecordsTable, BundleRecord>,
          ),
          BundleRecord,
          PrefetchHooks Function()
        > {
  $$BundleRecordsTableTableManager(_$AppDatabase db, $BundleRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BundleRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BundleRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BundleRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bundleId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> sourceNodeId = const Value.absent(),
                Value<String?> destinationNodeId = const Value.absent(),
                Value<String> destinationScope = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String?> ackForBundleId = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<String?> payloadRef = const Value.absent(),
                Value<String?> signature = const Value.absent(),
                Value<String> appId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int?> expiresAtMs = const Value.absent(),
                Value<int> ttlSeconds = const Value.absent(),
                Value<int> hopCount = const Value.absent(),
                Value<bool> acknowledged = const Value.absent(),
                Value<int?> sentAtMs = const Value.absent(),
                Value<int> failedAttempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BundleRecordsCompanion(
                bundleId: bundleId,
                type: type,
                sourceNodeId: sourceNodeId,
                destinationNodeId: destinationNodeId,
                destinationScope: destinationScope,
                priority: priority,
                ackForBundleId: ackForBundleId,
                payload: payload,
                payloadRef: payloadRef,
                signature: signature,
                appId: appId,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                ttlSeconds: ttlSeconds,
                hopCount: hopCount,
                acknowledged: acknowledged,
                sentAtMs: sentAtMs,
                failedAttempts: failedAttempts,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bundleId,
                required String type,
                required String sourceNodeId,
                Value<String?> destinationNodeId = const Value.absent(),
                Value<String> destinationScope = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String?> ackForBundleId = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<String?> payloadRef = const Value.absent(),
                Value<String?> signature = const Value.absent(),
                Value<String> appId = const Value.absent(),
                required int createdAtMs,
                Value<int?> expiresAtMs = const Value.absent(),
                required int ttlSeconds,
                Value<int> hopCount = const Value.absent(),
                Value<bool> acknowledged = const Value.absent(),
                Value<int?> sentAtMs = const Value.absent(),
                Value<int> failedAttempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BundleRecordsCompanion.insert(
                bundleId: bundleId,
                type: type,
                sourceNodeId: sourceNodeId,
                destinationNodeId: destinationNodeId,
                destinationScope: destinationScope,
                priority: priority,
                ackForBundleId: ackForBundleId,
                payload: payload,
                payloadRef: payloadRef,
                signature: signature,
                appId: appId,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                ttlSeconds: ttlSeconds,
                hopCount: hopCount,
                acknowledged: acknowledged,
                sentAtMs: sentAtMs,
                failedAttempts: failedAttempts,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BundleRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BundleRecordsTable,
      BundleRecord,
      $$BundleRecordsTableFilterComposer,
      $$BundleRecordsTableOrderingComposer,
      $$BundleRecordsTableAnnotationComposer,
      $$BundleRecordsTableCreateCompanionBuilder,
      $$BundleRecordsTableUpdateCompanionBuilder,
      (
        BundleRecord,
        BaseReferences<_$AppDatabase, $BundleRecordsTable, BundleRecord>,
      ),
      BundleRecord,
      PrefetchHooks Function()
    >;
typedef $$PeerContactsTableCreateCompanionBuilder =
    PeerContactsCompanion Function({
      required String nodeId,
      required String host,
      required int port,
      required int lastSeenMs,
      Value<int> seenCount,
      Value<int> rowid,
    });
typedef $$PeerContactsTableUpdateCompanionBuilder =
    PeerContactsCompanion Function({
      Value<String> nodeId,
      Value<String> host,
      Value<int> port,
      Value<int> lastSeenMs,
      Value<int> seenCount,
      Value<int> rowid,
    });

class $$PeerContactsTableFilterComposer
    extends Composer<_$AppDatabase, $PeerContactsTable> {
  $$PeerContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenMs => $composableBuilder(
    column: $table.lastSeenMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seenCount => $composableBuilder(
    column: $table.seenCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeerContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $PeerContactsTable> {
  $$PeerContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenMs => $composableBuilder(
    column: $table.lastSeenMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seenCount => $composableBuilder(
    column: $table.seenCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeerContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeerContactsTable> {
  $$PeerContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<int> get lastSeenMs => $composableBuilder(
    column: $table.lastSeenMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seenCount =>
      $composableBuilder(column: $table.seenCount, builder: (column) => column);
}

class $$PeerContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeerContactsTable,
          PeerContact,
          $$PeerContactsTableFilterComposer,
          $$PeerContactsTableOrderingComposer,
          $$PeerContactsTableAnnotationComposer,
          $$PeerContactsTableCreateCompanionBuilder,
          $$PeerContactsTableUpdateCompanionBuilder,
          (
            PeerContact,
            BaseReferences<_$AppDatabase, $PeerContactsTable, PeerContact>,
          ),
          PeerContact,
          PrefetchHooks Function()
        > {
  $$PeerContactsTableTableManager(_$AppDatabase db, $PeerContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeerContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeerContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeerContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> nodeId = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<int> lastSeenMs = const Value.absent(),
                Value<int> seenCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeerContactsCompanion(
                nodeId: nodeId,
                host: host,
                port: port,
                lastSeenMs: lastSeenMs,
                seenCount: seenCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeId,
                required String host,
                required int port,
                required int lastSeenMs,
                Value<int> seenCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeerContactsCompanion.insert(
                nodeId: nodeId,
                host: host,
                port: port,
                lastSeenMs: lastSeenMs,
                seenCount: seenCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeerContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeerContactsTable,
      PeerContact,
      $$PeerContactsTableFilterComposer,
      $$PeerContactsTableOrderingComposer,
      $$PeerContactsTableAnnotationComposer,
      $$PeerContactsTableCreateCompanionBuilder,
      $$PeerContactsTableUpdateCompanionBuilder,
      (
        PeerContact,
        BaseReferences<_$AppDatabase, $PeerContactsTable, PeerContact>,
      ),
      PeerContact,
      PrefetchHooks Function()
    >;
typedef $$SyncJobsTableCreateCompanionBuilder =
    SyncJobsCompanion Function({
      Value<int> id,
      required int startedAtMs,
      required int completedAtMs,
      Value<int> uploadedCount,
      Value<int> downloadedCount,
      required bool success,
      required bool mockMode,
      required bool gatewayEnabled,
      required bool internetReachable,
      Value<String?> errorMessage,
    });
typedef $$SyncJobsTableUpdateCompanionBuilder =
    SyncJobsCompanion Function({
      Value<int> id,
      Value<int> startedAtMs,
      Value<int> completedAtMs,
      Value<int> uploadedCount,
      Value<int> downloadedCount,
      Value<bool> success,
      Value<bool> mockMode,
      Value<bool> gatewayEnabled,
      Value<bool> internetReachable,
      Value<String?> errorMessage,
    });

class $$SyncJobsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uploadedCount => $composableBuilder(
    column: $table.uploadedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedCount => $composableBuilder(
    column: $table.downloadedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get success => $composableBuilder(
    column: $table.success,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mockMode => $composableBuilder(
    column: $table.mockMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get gatewayEnabled => $composableBuilder(
    column: $table.gatewayEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get internetReachable => $composableBuilder(
    column: $table.internetReachable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uploadedCount => $composableBuilder(
    column: $table.uploadedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedCount => $composableBuilder(
    column: $table.downloadedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get success => $composableBuilder(
    column: $table.success,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mockMode => $composableBuilder(
    column: $table.mockMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get gatewayEnabled => $composableBuilder(
    column: $table.gatewayEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get internetReachable => $composableBuilder(
    column: $table.internetReachable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uploadedCount => $composableBuilder(
    column: $table.uploadedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get downloadedCount => $composableBuilder(
    column: $table.downloadedCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get success =>
      $composableBuilder(column: $table.success, builder: (column) => column);

  GeneratedColumn<bool> get mockMode =>
      $composableBuilder(column: $table.mockMode, builder: (column) => column);

  GeneratedColumn<bool> get gatewayEnabled => $composableBuilder(
    column: $table.gatewayEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get internetReachable => $composableBuilder(
    column: $table.internetReachable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$SyncJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncJobsTable,
          SyncJob,
          $$SyncJobsTableFilterComposer,
          $$SyncJobsTableOrderingComposer,
          $$SyncJobsTableAnnotationComposer,
          $$SyncJobsTableCreateCompanionBuilder,
          $$SyncJobsTableUpdateCompanionBuilder,
          (SyncJob, BaseReferences<_$AppDatabase, $SyncJobsTable, SyncJob>),
          SyncJob,
          PrefetchHooks Function()
        > {
  $$SyncJobsTableTableManager(_$AppDatabase db, $SyncJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int> completedAtMs = const Value.absent(),
                Value<int> uploadedCount = const Value.absent(),
                Value<int> downloadedCount = const Value.absent(),
                Value<bool> success = const Value.absent(),
                Value<bool> mockMode = const Value.absent(),
                Value<bool> gatewayEnabled = const Value.absent(),
                Value<bool> internetReachable = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => SyncJobsCompanion(
                id: id,
                startedAtMs: startedAtMs,
                completedAtMs: completedAtMs,
                uploadedCount: uploadedCount,
                downloadedCount: downloadedCount,
                success: success,
                mockMode: mockMode,
                gatewayEnabled: gatewayEnabled,
                internetReachable: internetReachable,
                errorMessage: errorMessage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int startedAtMs,
                required int completedAtMs,
                Value<int> uploadedCount = const Value.absent(),
                Value<int> downloadedCount = const Value.absent(),
                required bool success,
                required bool mockMode,
                required bool gatewayEnabled,
                required bool internetReachable,
                Value<String?> errorMessage = const Value.absent(),
              }) => SyncJobsCompanion.insert(
                id: id,
                startedAtMs: startedAtMs,
                completedAtMs: completedAtMs,
                uploadedCount: uploadedCount,
                downloadedCount: downloadedCount,
                success: success,
                mockMode: mockMode,
                gatewayEnabled: gatewayEnabled,
                internetReachable: internetReachable,
                errorMessage: errorMessage,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncJobsTable,
      SyncJob,
      $$SyncJobsTableFilterComposer,
      $$SyncJobsTableOrderingComposer,
      $$SyncJobsTableAnnotationComposer,
      $$SyncJobsTableCreateCompanionBuilder,
      $$SyncJobsTableUpdateCompanionBuilder,
      (SyncJob, BaseReferences<_$AppDatabase, $SyncJobsTable, SyncJob>),
      SyncJob,
      PrefetchHooks Function()
    >;
typedef $$MessageProjectionsTableCreateCompanionBuilder =
    MessageProjectionsCompanion Function({
      required String bundleId,
      required String sourceNodeId,
      Value<String?> destinationNodeId,
      required String body,
      required int createdAtMs,
      required bool isOutgoing,
      required String deliveryStatus,
      Value<int> failedAttempts,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$MessageProjectionsTableUpdateCompanionBuilder =
    MessageProjectionsCompanion Function({
      Value<String> bundleId,
      Value<String> sourceNodeId,
      Value<String?> destinationNodeId,
      Value<String> body,
      Value<int> createdAtMs,
      Value<bool> isOutgoing,
      Value<String> deliveryStatus,
      Value<int> failedAttempts,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$MessageProjectionsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageProjectionsTable> {
  $$MessageProjectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bundleId => $composableBuilder(
    column: $table.bundleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationNodeId => $composableBuilder(
    column: $table.destinationNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageProjectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageProjectionsTable> {
  $$MessageProjectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bundleId => $composableBuilder(
    column: $table.bundleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationNodeId => $composableBuilder(
    column: $table.destinationNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageProjectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageProjectionsTable> {
  $$MessageProjectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bundleId =>
      $composableBuilder(column: $table.bundleId, builder: (column) => column);

  GeneratedColumn<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationNodeId => $composableBuilder(
    column: $table.destinationNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$MessageProjectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageProjectionsTable,
          MessageProjection,
          $$MessageProjectionsTableFilterComposer,
          $$MessageProjectionsTableOrderingComposer,
          $$MessageProjectionsTableAnnotationComposer,
          $$MessageProjectionsTableCreateCompanionBuilder,
          $$MessageProjectionsTableUpdateCompanionBuilder,
          (
            MessageProjection,
            BaseReferences<
              _$AppDatabase,
              $MessageProjectionsTable,
              MessageProjection
            >,
          ),
          MessageProjection,
          PrefetchHooks Function()
        > {
  $$MessageProjectionsTableTableManager(
    _$AppDatabase db,
    $MessageProjectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageProjectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageProjectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageProjectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> bundleId = const Value.absent(),
                Value<String> sourceNodeId = const Value.absent(),
                Value<String?> destinationNodeId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<bool> isOutgoing = const Value.absent(),
                Value<String> deliveryStatus = const Value.absent(),
                Value<int> failedAttempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageProjectionsCompanion(
                bundleId: bundleId,
                sourceNodeId: sourceNodeId,
                destinationNodeId: destinationNodeId,
                body: body,
                createdAtMs: createdAtMs,
                isOutgoing: isOutgoing,
                deliveryStatus: deliveryStatus,
                failedAttempts: failedAttempts,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bundleId,
                required String sourceNodeId,
                Value<String?> destinationNodeId = const Value.absent(),
                required String body,
                required int createdAtMs,
                required bool isOutgoing,
                required String deliveryStatus,
                Value<int> failedAttempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageProjectionsCompanion.insert(
                bundleId: bundleId,
                sourceNodeId: sourceNodeId,
                destinationNodeId: destinationNodeId,
                body: body,
                createdAtMs: createdAtMs,
                isOutgoing: isOutgoing,
                deliveryStatus: deliveryStatus,
                failedAttempts: failedAttempts,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageProjectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageProjectionsTable,
      MessageProjection,
      $$MessageProjectionsTableFilterComposer,
      $$MessageProjectionsTableOrderingComposer,
      $$MessageProjectionsTableAnnotationComposer,
      $$MessageProjectionsTableCreateCompanionBuilder,
      $$MessageProjectionsTableUpdateCompanionBuilder,
      (
        MessageProjection,
        BaseReferences<
          _$AppDatabase,
          $MessageProjectionsTable,
          MessageProjection
        >,
      ),
      MessageProjection,
      PrefetchHooks Function()
    >;
typedef $$AckEventsTableCreateCompanionBuilder =
    AckEventsCompanion Function({
      required String ackBundleId,
      Value<String?> ackForBundleId,
      required String sourceNodeId,
      required int firstReceivedAtMs,
      required int lastReceivedAtMs,
      Value<int> duplicateCount,
      Value<int> rowid,
    });
typedef $$AckEventsTableUpdateCompanionBuilder =
    AckEventsCompanion Function({
      Value<String> ackBundleId,
      Value<String?> ackForBundleId,
      Value<String> sourceNodeId,
      Value<int> firstReceivedAtMs,
      Value<int> lastReceivedAtMs,
      Value<int> duplicateCount,
      Value<int> rowid,
    });

class $$AckEventsTableFilterComposer
    extends Composer<_$AppDatabase, $AckEventsTable> {
  $$AckEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ackBundleId => $composableBuilder(
    column: $table.ackBundleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ackForBundleId => $composableBuilder(
    column: $table.ackForBundleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstReceivedAtMs => $composableBuilder(
    column: $table.firstReceivedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReceivedAtMs => $composableBuilder(
    column: $table.lastReceivedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duplicateCount => $composableBuilder(
    column: $table.duplicateCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AckEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $AckEventsTable> {
  $$AckEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ackBundleId => $composableBuilder(
    column: $table.ackBundleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ackForBundleId => $composableBuilder(
    column: $table.ackForBundleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstReceivedAtMs => $composableBuilder(
    column: $table.firstReceivedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReceivedAtMs => $composableBuilder(
    column: $table.lastReceivedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duplicateCount => $composableBuilder(
    column: $table.duplicateCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AckEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AckEventsTable> {
  $$AckEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ackBundleId => $composableBuilder(
    column: $table.ackBundleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ackForBundleId => $composableBuilder(
    column: $table.ackForBundleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstReceivedAtMs => $composableBuilder(
    column: $table.firstReceivedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReceivedAtMs => $composableBuilder(
    column: $table.lastReceivedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get duplicateCount => $composableBuilder(
    column: $table.duplicateCount,
    builder: (column) => column,
  );
}

class $$AckEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AckEventsTable,
          AckEvent,
          $$AckEventsTableFilterComposer,
          $$AckEventsTableOrderingComposer,
          $$AckEventsTableAnnotationComposer,
          $$AckEventsTableCreateCompanionBuilder,
          $$AckEventsTableUpdateCompanionBuilder,
          (AckEvent, BaseReferences<_$AppDatabase, $AckEventsTable, AckEvent>),
          AckEvent,
          PrefetchHooks Function()
        > {
  $$AckEventsTableTableManager(_$AppDatabase db, $AckEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AckEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AckEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AckEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ackBundleId = const Value.absent(),
                Value<String?> ackForBundleId = const Value.absent(),
                Value<String> sourceNodeId = const Value.absent(),
                Value<int> firstReceivedAtMs = const Value.absent(),
                Value<int> lastReceivedAtMs = const Value.absent(),
                Value<int> duplicateCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AckEventsCompanion(
                ackBundleId: ackBundleId,
                ackForBundleId: ackForBundleId,
                sourceNodeId: sourceNodeId,
                firstReceivedAtMs: firstReceivedAtMs,
                lastReceivedAtMs: lastReceivedAtMs,
                duplicateCount: duplicateCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ackBundleId,
                Value<String?> ackForBundleId = const Value.absent(),
                required String sourceNodeId,
                required int firstReceivedAtMs,
                required int lastReceivedAtMs,
                Value<int> duplicateCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AckEventsCompanion.insert(
                ackBundleId: ackBundleId,
                ackForBundleId: ackForBundleId,
                sourceNodeId: sourceNodeId,
                firstReceivedAtMs: firstReceivedAtMs,
                lastReceivedAtMs: lastReceivedAtMs,
                duplicateCount: duplicateCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AckEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AckEventsTable,
      AckEvent,
      $$AckEventsTableFilterComposer,
      $$AckEventsTableOrderingComposer,
      $$AckEventsTableAnnotationComposer,
      $$AckEventsTableCreateCompanionBuilder,
      $$AckEventsTableUpdateCompanionBuilder,
      (AckEvent, BaseReferences<_$AppDatabase, $AckEventsTable, AckEvent>),
      AckEvent,
      PrefetchHooks Function()
    >;
typedef $$ContentMetadataTableCreateCompanionBuilder =
    ContentMetadataCompanion Function({
      required String contentHash,
      Value<String?> mimeType,
      required int totalBytes,
      Value<int> chunkCount,
      required int createdAtMs,
      Value<String?> localPath,
      Value<int> rowid,
    });
typedef $$ContentMetadataTableUpdateCompanionBuilder =
    ContentMetadataCompanion Function({
      Value<String> contentHash,
      Value<String?> mimeType,
      Value<int> totalBytes,
      Value<int> chunkCount,
      Value<int> createdAtMs,
      Value<String?> localPath,
      Value<int> rowid,
    });

class $$ContentMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $ContentMetadataTable> {
  $$ContentMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentMetadataTable> {
  $$ContentMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentMetadataTable> {
  $$ContentMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);
}

class $$ContentMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentMetadataTable,
          ContentMetadataData,
          $$ContentMetadataTableFilterComposer,
          $$ContentMetadataTableOrderingComposer,
          $$ContentMetadataTableAnnotationComposer,
          $$ContentMetadataTableCreateCompanionBuilder,
          $$ContentMetadataTableUpdateCompanionBuilder,
          (
            ContentMetadataData,
            BaseReferences<
              _$AppDatabase,
              $ContentMetadataTable,
              ContentMetadataData
            >,
          ),
          ContentMetadataData,
          PrefetchHooks Function()
        > {
  $$ContentMetadataTableTableManager(
    _$AppDatabase db,
    $ContentMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> contentHash = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<int> chunkCount = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentMetadataCompanion(
                contentHash: contentHash,
                mimeType: mimeType,
                totalBytes: totalBytes,
                chunkCount: chunkCount,
                createdAtMs: createdAtMs,
                localPath: localPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentHash,
                Value<String?> mimeType = const Value.absent(),
                required int totalBytes,
                Value<int> chunkCount = const Value.absent(),
                required int createdAtMs,
                Value<String?> localPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentMetadataCompanion.insert(
                contentHash: contentHash,
                mimeType: mimeType,
                totalBytes: totalBytes,
                chunkCount: chunkCount,
                createdAtMs: createdAtMs,
                localPath: localPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentMetadataTable,
      ContentMetadataData,
      $$ContentMetadataTableFilterComposer,
      $$ContentMetadataTableOrderingComposer,
      $$ContentMetadataTableAnnotationComposer,
      $$ContentMetadataTableCreateCompanionBuilder,
      $$ContentMetadataTableUpdateCompanionBuilder,
      (
        ContentMetadataData,
        BaseReferences<
          _$AppDatabase,
          $ContentMetadataTable,
          ContentMetadataData
        >,
      ),
      ContentMetadataData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BundleRecordsTableTableManager get bundleRecords =>
      $$BundleRecordsTableTableManager(_db, _db.bundleRecords);
  $$PeerContactsTableTableManager get peerContacts =>
      $$PeerContactsTableTableManager(_db, _db.peerContacts);
  $$SyncJobsTableTableManager get syncJobs =>
      $$SyncJobsTableTableManager(_db, _db.syncJobs);
  $$MessageProjectionsTableTableManager get messageProjections =>
      $$MessageProjectionsTableTableManager(_db, _db.messageProjections);
  $$AckEventsTableTableManager get ackEvents =>
      $$AckEventsTableTableManager(_db, _db.ackEvents);
  $$ContentMetadataTableTableManager get contentMetadata =>
      $$ContentMetadataTableTableManager(_db, _db.contentMetadata);
}
