import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/chat_message.dart';

class ChatMessageBundleMapper {
  const ChatMessageBundleMapper();

  Bundle toBundle({
    required ChatMessage message,
    BundlePriority priority = BundlePriority.normal,
    int ttlSeconds = 3600,
    String appId = 'offlimu.chat',
  }) {
    return Bundle(
      bundleId: message.messageId,
      type: Bundle.typeChatMessage,
      sourceNodeId: message.sourceNodeId,
      destinationNodeId: message.destinationNodeId,
      destinationScope: message.destinationNodeId == null
          ? BundleDestinationScope.broadcast
          : BundleDestinationScope.direct,
      priority: priority,
      payload: message.body,
      appId: appId,
      createdAt: message.createdAt,
      ttlSeconds: ttlSeconds,
    );
  }

  ChatMessage? fromBundle({
    required Bundle bundle,
    required String localNodeId,
  }) {
    if (bundle.type != Bundle.typeChatMessage) {
      return null;
    }

    final bool isOutgoing = bundle.sourceNodeId == localNodeId;

    return ChatMessage(
      messageId: bundle.bundleId,
      sourceNodeId: bundle.sourceNodeId,
      destinationNodeId: bundle.destinationNodeId,
      body: bundle.payload ?? '',
      createdAt: bundle.createdAt,
      isOutgoing: isOutgoing,
      deliveryStatus: isOutgoing
          ? _deriveOutgoingStatus(bundle)
          : MessageDeliveryStatus.received,
      failedAttempts: bundle.failedAttempts,
      lastError: bundle.lastError,
    );
  }

  MessageDeliveryStatus _deriveOutgoingStatus(Bundle bundle) {
    if (bundle.acknowledged) {
      return MessageDeliveryStatus.acked;
    }
    if (bundle.failedAttempts > 0) {
      return MessageDeliveryStatus.failed;
    }
    if (bundle.sentAt != null) {
      return MessageDeliveryStatus.sent;
    }
    return MessageDeliveryStatus.pending;
  }
}
