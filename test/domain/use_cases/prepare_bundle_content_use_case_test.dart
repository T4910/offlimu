import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/use_cases/prepare_bundle_content_use_case.dart';

void main() {
  test(
    'attachUtf8Payload hashes bytes, stores metadata, and sets payloadRef',
    () async {
      final fakeBundles = _FakeBundleRepository();
      final fakeContentStore = _FakeContentStore();
      final fixedNow = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final useCase = PrepareBundleContentUseCase(
        bundles: fakeBundles,
        contentStore: fakeContentStore,
        now: () => fixedNow,
      );

      final original = Bundle(
        bundleId: 'b-1',
        type: Bundle.typeChatMessage,
        sourceNodeId: 'node-a',
        destinationNodeId: 'node-b',
        payload: 'hello world',
        createdAt: fixedNow,
        ttlSeconds: 3600,
      );

      final updated = await useCase.attachUtf8Payload(
        bundle: original,
        payload: 'hello world',
      );

      expect(updated.payloadReference, isNotNull);
      expect(updated.payloadReference, startsWith('sha256:'));
      expect(updated.payload, 'hello world');

      expect(fakeBundles.savedMetadata, hasLength(1));
      final metadata = fakeBundles.savedMetadata.single;
      expect(metadata.contentHash, updated.payloadReference);
      expect(metadata.totalBytes, 11);
      expect(metadata.chunkCount, 1);
      expect(metadata.mimeType, 'text/plain; charset=utf-8');
      expect(metadata.createdAt, fixedNow);
      expect(metadata.localPath, '/tmp/content/${metadata.contentHash}');

      expect(fakeContentStore.lastSavedHash, metadata.contentHash);
      expect(fakeContentStore.lastSavedBytes, isNotNull);
      expect(fakeContentStore.lastSavedBytes!.length, 11);
    },
  );
}

class _FakeContentStore implements ContentStore {
  String? lastSavedHash;
  Uint8List? lastSavedBytes;

  @override
  Future<String?> put({
    required String contentHash,
    required Uint8List bytes,
  }) async {
    lastSavedHash = contentHash;
    lastSavedBytes = bytes;
    return '/tmp/content/$contentHash';
  }

  @override
  Future<Uint8List?> read({required String contentHash}) {
    return Future<Uint8List?>.value(lastSavedBytes);
  }
}

class _FakeBundleRepository implements BundleRepository {
  final List<ContentMetadataRecord> savedMetadata = <ContentMetadataRecord>[];

  @override
  Future<Bundle?> getById(String bundleId) {
    return Future<Bundle?>.value(null);
  }

  @override
  Future<void> saveContentMetadata(ContentMetadataRecord metadata) async {
    savedMetadata.add(metadata);
  }

  @override
  Future<ContentMetadataRecord?> getContentMetadata(String contentHash) {
    for (final metadata in savedMetadata) {
      if (metadata.contentHash == contentHash) {
        return Future<ContentMetadataRecord?>.value(metadata);
      }
    }
    return Future<ContentMetadataRecord?>.value(null);
  }

  @override
  Stream<List<ContentMetadataRecord>> watchRecentContentMetadata({
    int limit = 50,
  }) {
    return Stream<List<ContentMetadataRecord>>.value(savedMetadata);
  }

  @override
  Future<void> markAcknowledged(String bundleId) => Future<void>.value();

  @override
  Future<void> markRejected(String bundleId, {required String reason}) {
    return Future<void>.value();
  }

  @override
  Future<void> markSendFailed(String bundleId, {required String errorMessage}) {
    return Future<void>.value();
  }

  @override
  Future<void> markSent(String bundleId) => Future<void>.value();

  @override
  Future<bool> recordAckReceipt(Bundle ackBundle) {
    return Future<bool>.value(false);
  }

  @override
  Future<void> save(Bundle bundle) => Future<void>.value();

  @override
  Future<List<Bundle>> getPendingBundles() =>
      Future<List<Bundle>>.value(const <Bundle>[]);

  @override
  Stream<List<Bundle>> watchBundlesByType(String type) {
    return const Stream<List<Bundle>>.empty();
  }

  @override
  Stream<List<Bundle>> watchPendingBundles() {
    return const Stream<List<Bundle>>.empty();
  }

  @override
  Stream<List<AckAuditEvent>> watchRecentAckEvents({int limit = 20}) {
    return const Stream<List<AckAuditEvent>>.empty();
  }
}
