import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/chat_thread.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';
import 'package:offlimu/infrastructure/db/drift_chat_message_repository.dart';

void main() {
  group('DriftChatMessageRepository', () {
    test(
      'aggregates direct threads from visible message projections',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        final bundles = DriftBundleRepository(db, localNodeId: 'node-a');
        final chats = DriftChatMessageRepository(db);

        await bundles.save(
          _chatBundle(
            id: 'chat-1',
            sourceNodeId: 'node-a',
            destinationNodeId: 'node-b',
            body: 'hello b',
            createdAtMs: 1000,
          ),
        );
        await bundles.save(
          _chatBundle(
            id: 'chat-2',
            sourceNodeId: 'node-b',
            destinationNodeId: 'node-a',
            body: 'hello a',
            createdAtMs: 2000,
          ),
        );

        final threads = await chats
            .watchThreads(localNodeId: 'node-a')
            .firstWhere((value) => value.isNotEmpty);
        final direct = threads.singleWhere(
          (thread) => thread.kind == ChatThreadKind.direct,
        );

        expect(direct.threadId, 'node-b');
        expect(direct.messageCount, 2);
        expect(direct.lastMessagePreview, 'hello a');
      },
    );

    test('aggregates broadcast thread and broadcast conversation', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final bundles = DriftBundleRepository(db, localNodeId: 'node-a');
      final chats = DriftChatMessageRepository(db);

      await bundles.save(
        _chatBundle(
          id: 'broadcast-1',
          sourceNodeId: 'node-a',
          destinationNodeId: null,
          body: 'hello everyone',
          createdAtMs: 1000,
        ),
      );
      await bundles.save(
        _chatBundle(
          id: 'broadcast-2',
          sourceNodeId: 'node-b',
          destinationNodeId: null,
          body: 'broadcast reply',
          createdAtMs: 2000,
        ),
      );

      final threads = await chats
          .watchThreads(localNodeId: 'node-a')
          .firstWhere((value) => value.isNotEmpty);
      final broadcast = threads.singleWhere(
        (thread) => thread.kind == ChatThreadKind.broadcast,
      );
      final messages = await chats
          .watchBroadcastConversation(localNodeId: 'node-a')
          .firstWhere((value) => value.length == 2);

      expect(broadcast.threadId, ChatThread.broadcastThreadId);
      expect(broadcast.messageCount, 2);
      expect(broadcast.lastMessagePreview, 'broadcast reply');
      expect(messages.map((message) => message.body), <String>[
        'broadcast reply',
        'hello everyone',
      ]);
    });

    test('filters direct conversations by peer', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final bundles = DriftBundleRepository(db, localNodeId: 'node-a');
      final chats = DriftChatMessageRepository(db);

      await bundles.save(
        _chatBundle(
          id: 'chat-b',
          sourceNodeId: 'node-a',
          destinationNodeId: 'node-b',
          body: 'for b',
          createdAtMs: 1000,
        ),
      );
      await bundles.save(
        _chatBundle(
          id: 'chat-c',
          sourceNodeId: 'node-a',
          destinationNodeId: 'node-c',
          body: 'for c',
          createdAtMs: 2000,
        ),
      );

      final messages = await chats
          .watchConversation(localNodeId: 'node-a', peerNodeId: 'node-b')
          .firstWhere((value) => value.length == 1);

      expect(messages.single.body, 'for b');
    });

    test('does not project relay-only chat bundles into chat UI', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final bundles = DriftBundleRepository(db, localNodeId: 'node-a');
      final chats = DriftChatMessageRepository(db);

      await bundles.save(
        _chatBundle(
          id: 'relay-only',
          sourceNodeId: 'node-b',
          destinationNodeId: 'node-c',
          body: 'not for local chat',
          createdAtMs: 1000,
        ),
      );

      final storedBundle = await bundles.getById('relay-only');
      final threads = await chats.watchThreads(localNodeId: 'node-a').first;
      final direct = await chats
          .watchConversation(localNodeId: 'node-a', peerNodeId: 'node-b')
          .first;

      expect(storedBundle, isNotNull);
      expect(threads, isEmpty);
      expect(direct, isEmpty);
    });
  });
}

Bundle _chatBundle({
  required String id,
  required String sourceNodeId,
  required String? destinationNodeId,
  required String body,
  required int createdAtMs,
}) {
  return Bundle(
    bundleId: id,
    type: Bundle.typeChatMessage,
    sourceNodeId: sourceNodeId,
    destinationNodeId: destinationNodeId,
    destinationScope: destinationNodeId == null
        ? BundleDestinationScope.broadcast
        : BundleDestinationScope.direct,
    payload: body,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    ttlSeconds: 3600,
  );
}
