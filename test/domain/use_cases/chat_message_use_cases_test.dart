import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/chat_message.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/use_cases/chat_message_bundle_mapper.dart';
import 'package:offlimu/domain/use_cases/prepare_bundle_content_use_case.dart';
import 'package:offlimu/domain/use_cases/receive_chat_message_use_case.dart';
import 'package:offlimu/domain/use_cases/send_chat_message_use_case.dart';

void main() {
  group('ChatMessageBundleMapper', () {
    test('maps outgoing chat message to direct bundle', () {
      final mapper = const ChatMessageBundleMapper();
      final createdAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);

      final message = ChatMessage(
        messageId: 'chat-1',
        sourceNodeId: 'node-a',
        destinationNodeId: 'node-b',
        body: 'hello',
        createdAt: createdAt,
        isOutgoing: true,
        deliveryStatus: MessageDeliveryStatus.pending,
      );

      final bundle = mapper.toBundle(
        message: message,
        priority: BundlePriority.high,
        ttlSeconds: 600,
      );

      expect(bundle.bundleId, 'chat-1');
      expect(bundle.type, Bundle.typeChatMessage);
      expect(bundle.sourceNodeId, 'node-a');
      expect(bundle.destinationNodeId, 'node-b');
      expect(bundle.destinationScope, BundleDestinationScope.direct);
      expect(bundle.priority, BundlePriority.high);
      expect(bundle.payload, 'hello');
      expect(bundle.ttlSeconds, 600);
    });

    test('maps chat bundle to incoming received message', () {
      final mapper = const ChatMessageBundleMapper();
      final bundle = Bundle(
        bundleId: 'chat-2',
        type: Bundle.typeChatMessage,
        sourceNodeId: 'node-b',
        destinationNodeId: 'node-a',
        payload: 'hi back',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000001000),
        ttlSeconds: 3600,
      );

      final message = mapper.fromBundle(bundle: bundle, localNodeId: 'node-a');

      expect(message, isNotNull);
      expect(message!.isOutgoing, isFalse);
      expect(message.deliveryStatus, MessageDeliveryStatus.received);
      expect(message.body, 'hi back');
    });
  });

  group('SendChatMessageUseCase', () {
    test('creates, prepares, and saves chat bundle', () async {
      final fakeBundles = _FakeBundleRepository();
      final fakeContentStore = _FakeContentStore();
      final prepare = PrepareBundleContentUseCase(
        bundles: fakeBundles,
        contentStore: fakeContentStore,
      );
      final useCase = SendChatMessageUseCase(
        bundles: fakeBundles,
        prepareBundleContent: prepare,
        mapper: const ChatMessageBundleMapper(),
        bundleSignatureService: _FakeBundleSignatureService(),
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000002000),
      );

      final saved = await useCase.send(
        localNodeId: 'node-a',
        destinationNodeId: 'node-b',
        body: 'offline hello',
      );

      expect(fakeBundles.savedBundles, hasLength(1));
      expect(fakeBundles.savedBundles.single.bundleId, saved.bundleId);
      expect(saved.payload, 'offline hello');
      expect(saved.payloadReference, startsWith('sha256:'));
      expect(fakeBundles.savedMetadata, hasLength(1));
    });

    test('throws for empty body', () async {
      final fakeBundles = _FakeBundleRepository();
      final fakeContentStore = _FakeContentStore();
      final useCase = SendChatMessageUseCase(
        bundles: fakeBundles,
        prepareBundleContent: PrepareBundleContentUseCase(
          bundles: fakeBundles,
          contentStore: fakeContentStore,
        ),
        mapper: const ChatMessageBundleMapper(),
        bundleSignatureService: _FakeBundleSignatureService(),
      );

      expect(
        () => useCase.send(localNodeId: 'node-a', body: '   '),
        throwsArgumentError,
      );
    });
  });

  group('ReceiveChatMessageUseCase', () {
    test('returns chat message when bundle is chat type', () {
      final useCase = ReceiveChatMessageUseCase(
        mapper: const ChatMessageBundleMapper(),
      );

      final bundle = Bundle(
        bundleId: 'chat-3',
        type: Bundle.typeChatMessage,
        sourceNodeId: 'node-z',
        payload: 'received payload',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000003000),
        ttlSeconds: 3600,
      );

      final message = useCase.receive(bundle: bundle, localNodeId: 'node-a');
      expect(message, isNotNull);
      expect(message!.messageId, 'chat-3');
      expect(message.body, 'received payload');
    });

    test('returns null for non-chat bundle', () {
      final useCase = ReceiveChatMessageUseCase(
        mapper: const ChatMessageBundleMapper(),
      );

      final bundle = Bundle(
        bundleId: 'ack-1',
        type: Bundle.typeAck,
        sourceNodeId: 'node-z',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000004000),
        ttlSeconds: 300,
      );

      final message = useCase.receive(bundle: bundle, localNodeId: 'node-a');
      expect(message, isNull);
    });
  });
}

class _FakeContentStore implements ContentStore {
  @override
  Future<String?> put({
    required String contentHash,
    required Uint8List bytes,
  }) async {
    return '/tmp/content/$contentHash';
  }

  @override
  Future<Uint8List?> read({required String contentHash}) {
    return Future<Uint8List?>.value(null);
  }
}

class _FakeBundleRepository implements BundleRepository {
  final List<Bundle> savedBundles = <Bundle>[];
  final List<ContentMetadataRecord> savedMetadata = <ContentMetadataRecord>[];

  @override
  Future<Bundle?> getById(String bundleId) {
    return Future<Bundle?>.value(null);
  }

  @override
  Future<void> save(Bundle bundle) async {
    savedBundles.add(bundle);
  }

  @override
  Future<void> saveContentMetadata(ContentMetadataRecord metadata) async {
    savedMetadata.add(metadata);
  }

  @override
  Future<ContentMetadataRecord?> getContentMetadata(String contentHash) async {
    for (final metadata in savedMetadata) {
      if (metadata.contentHash == contentHash) {
        return metadata;
      }
    }
    return null;
  }

  @override
  Stream<List<ContentMetadataRecord>> watchRecentContentMetadata({
    int limit = 50,
  }) {
    return Stream<List<ContentMetadataRecord>>.value(savedMetadata);
  }

  @override
  Future<void> markSent(String bundleId) => Future<void>.value();

  @override
  Future<void> markSendFailed(String bundleId, {required String errorMessage}) {
    return Future<void>.value();
  }

  @override
  Future<void> markRejected(String bundleId, {required String reason}) {
    return Future<void>.value();
  }

  @override
  Future<void> markAcknowledged(String bundleId) => Future<void>.value();

  @override
  Future<bool> recordAckReceipt(Bundle ackBundle) {
    return Future<bool>.value(false);
  }

  @override
  Future<List<Bundle>> getPendingBundles() {
    return Future<List<Bundle>>.value(const <Bundle>[]);
  }

  @override
  Stream<List<Bundle>> watchPendingBundles() {
    return const Stream<List<Bundle>>.empty();
  }

  @override
  Stream<List<Bundle>> watchBundlesByType(String type) {
    return const Stream<List<Bundle>>.empty();
  }

  @override
  Stream<List<AckAuditEvent>> watchRecentAckEvents({int limit = 20}) {
    return const Stream<List<AckAuditEvent>>.empty();
  }
}

class _FakeBundleSignatureService implements BundleSignatureService {
  @override
  Future<Bundle> sign({required Bundle bundle, required String nodeId}) async {
    return bundle;
  }

  @override
  Future<bool> verify(Bundle bundle) async => true;
}
