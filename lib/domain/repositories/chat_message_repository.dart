import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/entities/chat_thread.dart';

abstract interface class ChatMessageRepository {
  Stream<List<ChatMessage>> watchRecentMessages({int limit = 200});

  Stream<List<ChatThread>> watchThreads({required String localNodeId});

  Stream<List<ChatMessage>> watchConversation({
    required String localNodeId,
    required String peerNodeId,
    int limit = 200,
  });

  Stream<List<ChatMessage>> watchBroadcastConversation({
    required String localNodeId,
    int limit = 200,
  });
}
