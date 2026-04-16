import 'package:drift/drift.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/repositories/chat_message_repository.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';

class DriftChatMessageRepository implements ChatMessageRepository {
  DriftChatMessageRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ChatMessage>> watchRecentMessages({int limit = 200}) {
    final query = (_db.select(_db.messageProjections)
      ..orderBy(
        <OrderingTerm Function($MessageProjectionsTable)>[
          (tbl) => OrderingTerm.desc(tbl.createdAtMs),
        ],
      )
      ..limit(limit));

    return query.watch().map(
          (rows) => rows.map(_toEntity).toList(growable: false),
        );
  }

  ChatMessage _toEntity(MessageProjection row) {
    return ChatMessage(
      messageId: row.bundleId,
      sourceNodeId: row.sourceNodeId,
      destinationNodeId: row.destinationNodeId,
      body: row.body,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      isOutgoing: row.isOutgoing,
      deliveryStatus: _parseStatus(row.deliveryStatus),
      failedAttempts: row.failedAttempts,
      lastError: row.lastError,
    );
  }

  MessageDeliveryStatus _parseStatus(String status) {
    for (final candidate in MessageDeliveryStatus.values) {
      if (candidate.name == status) {
        return candidate;
      }
    }
    return MessageDeliveryStatus.pending;
  }
}
