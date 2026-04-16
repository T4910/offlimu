import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/use_cases/chat_message_bundle_mapper.dart';

class ReceiveChatMessageUseCase {
  const ReceiveChatMessageUseCase({required ChatMessageBundleMapper mapper})
    : _mapper = mapper;

  final ChatMessageBundleMapper _mapper;

  ChatMessage? receive({required Bundle bundle, required String localNodeId}) {
    return _mapper.fromBundle(bundle: bundle, localNodeId: localNodeId);
  }
}
