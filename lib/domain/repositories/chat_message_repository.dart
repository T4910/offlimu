import 'package:offlimu/domain/entities/chat_message.dart';

abstract interface class ChatMessageRepository {
  Stream<List<ChatMessage>> watchRecentMessages({int limit = 200});
}
