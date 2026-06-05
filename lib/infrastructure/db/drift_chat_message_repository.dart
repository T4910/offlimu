import 'package:drift/drift.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/entities/chat_thread.dart';
import 'package:offlimu/domain/repositories/chat_message_repository.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';

class DriftChatMessageRepository implements ChatMessageRepository {
  DriftChatMessageRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ChatMessage>> watchRecentMessages({int limit = 200}) {
    final query = (_db.select(_db.messageProjections)
      ..orderBy(<OrderingTerm Function($MessageProjectionsTable)>[
        (tbl) => OrderingTerm.desc(tbl.createdAtMs),
      ])
      ..limit(limit));

    return query.watch().map(
      (rows) => rows.map(_toEntity).toList(growable: false),
    );
  }

  @override
  Stream<List<ChatThread>> watchThreads({required String localNodeId}) {
    final query = (_db.select(_db.messageProjections)
      ..orderBy(<OrderingTerm Function($MessageProjectionsTable)>[
        (tbl) => OrderingTerm.desc(tbl.createdAtMs),
      ]));

    return query.watch().map((rows) {
      final Map<String, _ThreadAccumulator> directThreads =
          <String, _ThreadAccumulator>{};
      _ThreadAccumulator? broadcast;

      for (final row in rows) {
        if (_isBroadcast(row)) {
          broadcast ??= _ThreadAccumulator(
            threadId: ChatThread.broadcastThreadId,
            kind: ChatThreadKind.broadcast,
            title: 'Broadcast',
          );
          broadcast.add(row);
          continue;
        }

        final String peerNodeId = _peerNodeId(row, localNodeId);
        if (peerNodeId.isEmpty || peerNodeId == localNodeId) {
          continue;
        }

        directThreads
            .putIfAbsent(
              peerNodeId,
              () => _ThreadAccumulator(
                threadId: peerNodeId,
                kind: ChatThreadKind.direct,
                title: peerNodeId,
              ),
            )
            .add(row);
      }

      return <ChatThread>[
        if (broadcast != null) broadcast.toThread(),
        ...directThreads.values.map((accumulator) => accumulator.toThread()),
      ];
    });
  }

  @override
  Stream<List<ChatMessage>> watchConversation({
    required String localNodeId,
    required String peerNodeId,
    int limit = 200,
  }) {
    final query = (_db.select(_db.messageProjections)
      ..where(
        (tbl) =>
            (tbl.sourceNodeId.equals(localNodeId) &
                tbl.destinationNodeId.equals(peerNodeId)) |
            (tbl.sourceNodeId.equals(peerNodeId) &
                tbl.destinationNodeId.equals(localNodeId)),
      )
      ..orderBy(<OrderingTerm Function($MessageProjectionsTable)>[
        (tbl) => OrderingTerm.desc(tbl.createdAtMs),
      ])
      ..limit(limit));

    return query.watch().map(
      (rows) => rows.map(_toEntity).toList(growable: false),
    );
  }

  @override
  Stream<List<ChatMessage>> watchBroadcastConversation({
    required String localNodeId,
    int limit = 200,
  }) {
    final query = (_db.select(_db.messageProjections)
      ..where((tbl) => tbl.destinationNodeId.isNull())
      ..orderBy(<OrderingTerm Function($MessageProjectionsTable)>[
        (tbl) => OrderingTerm.desc(tbl.createdAtMs),
      ])
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

  bool _isBroadcast(MessageProjection row) => row.destinationNodeId == null;

  String _peerNodeId(MessageProjection row, String localNodeId) {
    if (row.sourceNodeId == localNodeId) {
      return row.destinationNodeId ?? '';
    }
    return row.sourceNodeId;
  }
}

class _ThreadAccumulator {
  _ThreadAccumulator({
    required this.threadId,
    required this.kind,
    required this.title,
  });

  final String threadId;
  final ChatThreadKind kind;
  final String title;
  int messageCount = 0;
  MessageProjection? latest;

  void add(MessageProjection row) {
    messageCount++;
    final currentLatest = latest;
    if (currentLatest == null || row.createdAtMs > currentLatest.createdAtMs) {
      latest = row;
    }
  }

  ChatThread toThread() {
    final row = latest;
    return ChatThread(
      threadId: threadId,
      kind: kind,
      title: title,
      lastMessagePreview: row?.body,
      lastMessageAt: row == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      messageCount: messageCount,
      lastDeliveryStatus: row == null ? null : _parseStatus(row.deliveryStatus),
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
