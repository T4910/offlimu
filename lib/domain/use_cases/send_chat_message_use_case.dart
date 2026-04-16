import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/use_cases/chat_message_bundle_mapper.dart';
import 'package:offlimu/domain/use_cases/prepare_bundle_content_use_case.dart';

class SendChatMessageUseCase {
  SendChatMessageUseCase({
    required BundleRepository bundles,
    required PrepareBundleContentUseCase prepareBundleContent,
    required ChatMessageBundleMapper mapper,
    required BundleSignatureService bundleSignatureService,
    DateTime Function()? now,
  }) : _bundles = bundles,
       _prepareBundleContent = prepareBundleContent,
       _mapper = mapper,
       _bundleSignatureService = bundleSignatureService,
       _now = now ?? DateTime.now;

  final BundleRepository _bundles;
  final PrepareBundleContentUseCase _prepareBundleContent;
  final ChatMessageBundleMapper _mapper;
  final BundleSignatureService _bundleSignatureService;
  final DateTime Function() _now;

  Future<Bundle> send({
    required String localNodeId,
    required String body,
    String? destinationNodeId,
    BundlePriority priority = BundlePriority.normal,
    int ttlSeconds = 3600,
    String appId = 'offlimu.chat',
  }) async {
    final String trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      throw ArgumentError('Message body must not be empty.');
    }

    final DateTime createdAt = _now();
    final ChatMessage message = ChatMessage(
      messageId: 'chat-${createdAt.microsecondsSinceEpoch}',
      sourceNodeId: localNodeId,
      destinationNodeId: destinationNodeId,
      body: trimmedBody,
      createdAt: createdAt,
      isOutgoing: true,
      deliveryStatus: MessageDeliveryStatus.pending,
    );

    final Bundle bundle = _mapper.toBundle(
      message: message,
      priority: priority,
      ttlSeconds: ttlSeconds,
      appId: appId,
    );

    final Bundle prepared = await _prepareBundleContent.attachUtf8Payload(
      bundle: bundle,
      payload: trimmedBody,
    );

    final Bundle signed = await _bundleSignatureService.sign(
      bundle: prepared,
      nodeId: localNodeId,
    );

    await _bundles.save(signed);
    return signed;
  }
}
