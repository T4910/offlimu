import 'package:offlimu/domain/entities/chat_message.dart';

enum ChatThreadKind { direct, broadcast }

class ChatThread {
  const ChatThread({
    required this.threadId,
    required this.kind,
    required this.title,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.messageCount,
    this.lastDeliveryStatus,
  });

  static const String broadcastThreadId = 'broadcast';

  final String threadId;
  final ChatThreadKind kind;
  final String title;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int messageCount;
  final MessageDeliveryStatus? lastDeliveryStatus;

  bool get hasMessages => messageCount > 0;
}
