import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:drift/drift.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';

class DriftBundleRepository implements BundleRepository {
  DriftBundleRepository(this._db, {required String localNodeId})
    : _localNodeId = localNodeId;

  final AppDatabase _db;
  final String _localNodeId;

  @override
  Future<void> save(Bundle bundle) async {
    await _db.transaction(() async {
      await _db
          .into(_db.bundleRecords)
          .insertOnConflictUpdate(
            BundleRecordsCompanion(
              bundleId: Value<String>(bundle.bundleId),
              type: Value<String>(bundle.type),
              sourceNodeId: Value<String>(bundle.sourceNodeId),
              destinationNodeId: Value<String?>(bundle.destinationNodeId),
              destinationScope: Value<String>(bundle.destinationScope.name),
              priority: Value<String>(bundle.priority.name),
              ackForBundleId: Value<String?>(bundle.ackForBundleId),
              payload: Value<String?>(bundle.payload),
              payloadRef: Value<String?>(bundle.payloadReference),
              signature: Value<String?>(bundle.signature),
              appId: Value<String>(bundle.appId),
              createdAtMs: Value<int>(bundle.createdAt.millisecondsSinceEpoch),
              expiresAtMs: Value<int?>(
                bundle.expiresAtOverride?.millisecondsSinceEpoch,
              ),
              ttlSeconds: Value<int>(bundle.ttlSeconds),
              hopCount: Value<int>(bundle.hopCount),
              acknowledged: Value<bool>(bundle.acknowledged),
              sentAtMs: Value<int?>(bundle.sentAt?.millisecondsSinceEpoch),
              failedAttempts: Value<int>(bundle.failedAttempts),
              lastError: Value<String?>(bundle.lastError),
            ),
          );
      await _upsertMessageProjection(bundle);
    });
  }

  @override
  Future<Bundle?> getById(String bundleId) async {
    final row = await (_db.select(
      _db.bundleRecords,
    )..where((tbl) => tbl.bundleId.equals(bundleId))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toEntity(row);
  }

  @override
  Future<void> saveContentMetadata(ContentMetadataRecord metadata) {
    return _db
        .into(_db.contentMetadata)
        .insertOnConflictUpdate(
          ContentMetadataCompanion(
            contentHash: Value<String>(metadata.contentHash),
            mimeType: Value<String?>(metadata.mimeType),
            totalBytes: Value<int>(metadata.totalBytes),
            chunkCount: Value<int>(metadata.chunkCount),
            createdAtMs: Value<int>(metadata.createdAt.millisecondsSinceEpoch),
            localPath: Value<String?>(metadata.localPath),
          ),
        );
  }

  @override
  Future<ContentMetadataRecord?> getContentMetadata(String contentHash) async {
    final row = await (_db.select(
      _db.contentMetadata,
    )..where((tbl) => tbl.contentHash.equals(contentHash))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toContentMetadataEntity(row);
  }

  @override
  Stream<List<ContentMetadataRecord>> watchRecentContentMetadata({
    int limit = 50,
  }) {
    final query = (_db.select(_db.contentMetadata)
      ..orderBy(<OrderingTerm Function($ContentMetadataTable)>[
        (tbl) => OrderingTerm.desc(tbl.createdAtMs),
      ])
      ..limit(limit));

    return query.watch().map(
      (rows) => rows.map(_toContentMetadataEntity).toList(growable: false),
    );
  }

  @override
  Future<void> markSent(String bundleId) async {
    await _db.transaction(() async {
      await (_db.update(
        _db.bundleRecords,
      )..where((tbl) => tbl.bundleId.equals(bundleId))).write(
        BundleRecordsCompanion(
          sentAtMs: Value<int>(DateTime.now().millisecondsSinceEpoch),
          failedAttempts: const Value<int>(0),
          lastError: const Value<String?>(null),
        ),
      );

      await (_db.update(
        _db.messageProjections,
      )..where((tbl) => tbl.bundleId.equals(bundleId))).write(
        MessageProjectionsCompanion(
          deliveryStatus: Value<String>(MessageDeliveryStatus.sent.name),
          failedAttempts: const Value<int>(0),
          lastError: const Value<String?>(null),
        ),
      );
    });
  }

  @override
  Future<void> markSendFailed(
    String bundleId, {
    required String errorMessage,
  }) async {
    final BundleRecord? row = await (_db.select(
      _db.bundleRecords,
    )..where((tbl) => tbl.bundleId.equals(bundleId))).getSingleOrNull();

    if (row == null) {
      return;
    }

    final nextFailures = row.failedAttempts + 1;

    await _db.transaction(() async {
      await (_db.update(
        _db.bundleRecords,
      )..where((tbl) => tbl.bundleId.equals(bundleId))).write(
        BundleRecordsCompanion(
          sentAtMs: Value<int>(DateTime.now().millisecondsSinceEpoch),
          failedAttempts: Value<int>(nextFailures),
          lastError: Value<String>(errorMessage),
        ),
      );

      await (_db.update(
        _db.messageProjections,
      )..where((tbl) => tbl.bundleId.equals(bundleId))).write(
        MessageProjectionsCompanion(
          deliveryStatus: Value<String>(MessageDeliveryStatus.failed.name),
          failedAttempts: Value<int>(nextFailures),
          lastError: Value<String>(errorMessage),
        ),
      );
    });
  }

  @override
  Future<void> markRejected(String bundleId, {required String reason}) async {
    final BundleRecord? row = await (_db.select(
      _db.bundleRecords,
    )..where((tbl) => tbl.bundleId.equals(bundleId))).getSingleOrNull();

    if (row == null) {
      return;
    }

    final nextFailures = row.failedAttempts + 1;

    await _db.transaction(() async {
      await (_db.update(
        _db.bundleRecords,
      )..where((tbl) => tbl.bundleId.equals(bundleId))).write(
        BundleRecordsCompanion(
          acknowledged: const Value<bool>(true),
          failedAttempts: Value<int>(nextFailures),
          lastError: Value<String>(reason),
        ),
      );

      await (_db.update(
        _db.messageProjections,
      )..where((tbl) => tbl.bundleId.equals(bundleId))).write(
        MessageProjectionsCompanion(
          deliveryStatus: Value<String>(MessageDeliveryStatus.failed.name),
          failedAttempts: Value<int>(nextFailures),
          lastError: Value<String>(reason),
        ),
      );
    });
  }

  @override
  Future<void> markAcknowledged(String bundleId) async {
    await _db.transaction(() async {
      await (_db.update(_db.bundleRecords)
            ..where((tbl) => tbl.bundleId.equals(bundleId)))
          .write(const BundleRecordsCompanion(acknowledged: Value<bool>(true)));

      final projection = await (_db.select(
        _db.messageProjections,
      )..where((tbl) => tbl.bundleId.equals(bundleId))).getSingleOrNull();
      if (projection == null) {
        return;
      }

      final status = projection.isOutgoing
          ? MessageDeliveryStatus.acked.name
          : MessageDeliveryStatus.received.name;

      await (_db.update(
        _db.messageProjections,
      )..where((tbl) => tbl.bundleId.equals(bundleId))).write(
        MessageProjectionsCompanion(deliveryStatus: Value<String>(status)),
      );
    });
  }

  @override
  Future<bool> recordAckReceipt(Bundle ackBundle) async {
    if (!ackBundle.isAck) {
      return false;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    return _db.transaction(() async {
      final existing =
          await (_db.select(_db.ackEvents)
                ..where((tbl) => tbl.ackBundleId.equals(ackBundle.bundleId)))
              .getSingleOrNull();

      if (existing == null) {
        await _db
            .into(_db.ackEvents)
            .insert(
              AckEventsCompanion.insert(
                ackBundleId: ackBundle.bundleId,
                ackForBundleId: Value<String?>(ackBundle.ackForBundleId),
                sourceNodeId: ackBundle.sourceNodeId,
                firstReceivedAtMs: nowMs,
                lastReceivedAtMs: nowMs,
                duplicateCount: const Value<int>(0),
              ),
            );
        return true;
      }

      await (_db.update(
        _db.ackEvents,
      )..where((tbl) => tbl.ackBundleId.equals(ackBundle.bundleId))).write(
        AckEventsCompanion(
          lastReceivedAtMs: Value<int>(nowMs),
          duplicateCount: Value<int>(existing.duplicateCount + 1),
        ),
      );
      return false;
    });
  }

  @override
  Future<List<Bundle>> getPendingBundles() async {
    final List<BundleRecord> rows = await _pendingQuery().get();
    return rows.map(_toEntity).toList(growable: false);
  }

  @override
  Stream<List<Bundle>> watchPendingBundles() {
    return _pendingQuery().watch().map(
      (rows) => rows.map(_toEntity).toList(growable: false),
    );
  }

  @override
  Stream<List<Bundle>> watchBundlesByType(String type) {
    final query = (_db.select(_db.bundleRecords)
      ..where((tbl) => tbl.type.equals(type))
      ..orderBy(<OrderingTerm Function($BundleRecordsTable)>[
        (tbl) => OrderingTerm.desc(tbl.createdAtMs),
      ]));

    return query.watch().map(
      (rows) => rows.map(_toEntity).toList(growable: false),
    );
  }

  @override
  Stream<List<AckAuditEvent>> watchRecentAckEvents({int limit = 20}) {
    final query = (_db.select(_db.ackEvents)
      ..orderBy(<OrderingTerm Function($AckEventsTable)>[
        (tbl) => OrderingTerm.desc(tbl.lastReceivedAtMs),
      ])
      ..limit(limit));

    return query.watch().map(
      (rows) => rows.map(_toAckEvent).toList(growable: false),
    );
  }

  SimpleSelectStatement<$BundleRecordsTable, BundleRecord> _pendingQuery() {
    return (_db.select(_db.bundleRecords)
      ..where((tbl) => tbl.acknowledged.equals(false))
      ..orderBy(<OrderingTerm Function($BundleRecordsTable)>[
        (tbl) => OrderingTerm.asc(tbl.createdAtMs),
      ]));
  }

  Bundle _toEntity(BundleRecord row) {
    return Bundle(
      bundleId: row.bundleId,
      type: row.type,
      sourceNodeId: row.sourceNodeId,
      destinationNodeId: row.destinationNodeId,
      destinationScope: Bundle.destinationScopeFromWire(row.destinationScope),
      priority: Bundle.priorityFromWire(row.priority),
      ackForBundleId: row.ackForBundleId,
      payload: row.payload,
      payloadReference: row.payloadRef,
      signature: row.signature,
      appId: row.appId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      expiresAtOverride: row.expiresAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.expiresAtMs!),
      ttlSeconds: row.ttlSeconds,
      hopCount: row.hopCount,
      acknowledged: row.acknowledged,
      sentAt: row.sentAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.sentAtMs!),
      failedAttempts: row.failedAttempts,
      lastError: row.lastError,
    );
  }

  AckAuditEvent _toAckEvent(AckEvent row) {
    return AckAuditEvent(
      ackBundleId: row.ackBundleId,
      ackForBundleId: row.ackForBundleId,
      sourceNodeId: row.sourceNodeId,
      firstReceivedAt: DateTime.fromMillisecondsSinceEpoch(
        row.firstReceivedAtMs,
      ),
      lastReceivedAt: DateTime.fromMillisecondsSinceEpoch(row.lastReceivedAtMs),
      duplicateCount: row.duplicateCount,
    );
  }

  ContentMetadataRecord _toContentMetadataEntity(ContentMetadataData row) {
    return ContentMetadataRecord(
      contentHash: row.contentHash,
      mimeType: row.mimeType,
      totalBytes: row.totalBytes,
      chunkCount: row.chunkCount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      localPath: row.localPath,
    );
  }

  Future<void> _upsertMessageProjection(Bundle bundle) {
    if (bundle.type != Bundle.typeChatMessage) {
      return Future<void>.value();
    }

    final bool isOutgoing = bundle.sourceNodeId == _localNodeId;
    final String status = isOutgoing
        ? _deriveOutgoingStatus(bundle)
        : MessageDeliveryStatus.received.name;

    return _db
        .into(_db.messageProjections)
        .insertOnConflictUpdate(
          MessageProjectionsCompanion(
            bundleId: Value<String>(bundle.bundleId),
            sourceNodeId: Value<String>(bundle.sourceNodeId),
            destinationNodeId: Value<String?>(bundle.destinationNodeId),
            body: Value<String>(bundle.payload ?? ''),
            createdAtMs: Value<int>(bundle.createdAt.millisecondsSinceEpoch),
            isOutgoing: Value<bool>(isOutgoing),
            deliveryStatus: Value<String>(status),
            failedAttempts: Value<int>(bundle.failedAttempts),
            lastError: Value<String?>(bundle.lastError),
          ),
        );
  }

  String _deriveOutgoingStatus(Bundle bundle) {
    if (bundle.acknowledged) {
      return MessageDeliveryStatus.acked.name;
    }
    if (bundle.failedAttempts > 0) {
      return MessageDeliveryStatus.failed.name;
    }
    if (bundle.sentAt != null) {
      return MessageDeliveryStatus.sent.name;
    }
    return MessageDeliveryStatus.pending.name;
  }
}
