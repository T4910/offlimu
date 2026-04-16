enum MessageDeliveryStatus { pending, sent, acked, failed, received }

class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.sourceNodeId,
    required this.destinationNodeId,
    required this.body,
    required this.createdAt,
    required this.isOutgoing,
    required this.deliveryStatus,
    this.failedAttempts = 0,
    this.lastError,
  });

  final String messageId;
  final String sourceNodeId;
  final String? destinationNodeId;
  final String body;
  final DateTime createdAt;
  final bool isOutgoing;
  final MessageDeliveryStatus deliveryStatus;
  final int failedAttempts;
  final String? lastError;
}
