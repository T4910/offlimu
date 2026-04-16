import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/use_cases/prepare_bundle_content_use_case.dart';
import 'package:offlimu/domain/use_cases/send_file_transfer_use_case.dart';

void main() {
  test('send file transfer creates manifest and chunk bundles', () async {
    final fakeBundles = _FakeBundleRepository();
    final fakeContentStore = _FakeContentStore();
    final prepare = PrepareBundleContentUseCase(
      bundles: fakeBundles,
      contentStore: fakeContentStore,
      now: () => DateTime.fromMillisecondsSinceEpoch(1700000005000),
    );
    final useCase = SendFileTransferUseCase(
      bundles: fakeBundles,
      prepareBundleContent: prepare,
      bundleSignatureService: _FakeBundleSignatureService(),
      now: () => DateTime.fromMillisecondsSinceEpoch(1700000006000),
      chunkSizeBytes: 4,
    );

    final result = await useCase.send(
      localNodeId: 'node-a',
      destinationNodeId: 'node-b',
      fileName: 'notes.txt',
      bytes: Uint8List.fromList('hello world'.codeUnits),
      mimeType: 'text/plain',
    );

    expect(result.chunkCount, 3);
    expect(result.contentHash, startsWith('sha256:'));
    expect(result.manifestBundle.type, Bundle.typeFileShareMetadata);
    expect(result.manifestBundle.payloadReference, result.contentHash);

    expect(fakeBundles.savedBundles, hasLength(4));
    expect(fakeBundles.savedBundles.first.type, Bundle.typeFileShareMetadata);
    expect(
      fakeBundles.savedBundles.where(
        (bundle) => bundle.type == Bundle.typeFileShareChunk,
      ),
      hasLength(3),
    );
    expect(fakeBundles.savedMetadata.last.chunkCount, 3);
    expect(fakeBundles.savedMetadata.last.totalBytes, 11);

    expect(result.manifestBundle.bundleId, contains('node-b'));
    expect(
      fakeBundles.savedBundles
          .where((bundle) => bundle.type == Bundle.typeFileShareChunk)
          .every((bundle) => bundle.bundleId.contains('node-b')),
      isTrue,
    );
  });

  test('send file transfer resumes by skipping existing bundles', () async {
    final fakeBundles = _FakeBundleRepository();
    final fakeContentStore = _FakeContentStore();
    final prepare = PrepareBundleContentUseCase(
      bundles: fakeBundles,
      contentStore: fakeContentStore,
      now: () => DateTime.fromMillisecondsSinceEpoch(1700000005000),
    );
    final useCase = SendFileTransferUseCase(
      bundles: fakeBundles,
      prepareBundleContent: prepare,
      bundleSignatureService: _FakeBundleSignatureService(),
      now: () => DateTime.fromMillisecondsSinceEpoch(1700000006000),
      chunkSizeBytes: 4,
    );

    final Uint8List bytes = Uint8List.fromList('hello world'.codeUnits);
    final firstDispatch = await useCase.send(
      localNodeId: 'node-a',
      destinationNodeId: 'node-b',
      fileName: 'notes.txt',
      bytes: bytes,
      mimeType: 'text/plain',
    );
    expect(fakeBundles.savedBundles, hasLength(4));

    fakeBundles.savedBundles.clear();

    final secondDispatch = await useCase.send(
      localNodeId: 'node-a',
      destinationNodeId: 'node-b',
      fileName: 'notes.txt',
      bytes: bytes,
      mimeType: 'text/plain',
    );

    expect(secondDispatch.contentHash, firstDispatch.contentHash);
    expect(
      secondDispatch.manifestBundle.bundleId,
      firstDispatch.manifestBundle.bundleId,
    );
    expect(fakeBundles.savedBundles, isEmpty);
  });

  test('send file transfer reports progress for each chunk', () async {
    final fakeBundles = _FakeBundleRepository();
    final fakeContentStore = _FakeContentStore();
    final prepare = PrepareBundleContentUseCase(
      bundles: fakeBundles,
      contentStore: fakeContentStore,
      now: () => DateTime.fromMillisecondsSinceEpoch(1700000005000),
    );
    final useCase = SendFileTransferUseCase(
      bundles: fakeBundles,
      prepareBundleContent: prepare,
      bundleSignatureService: _FakeBundleSignatureService(),
      now: () => DateTime.fromMillisecondsSinceEpoch(1700000006000),
      chunkSizeBytes: 4,
    );

    final List<FileTransferProgress> progressEvents = <FileTransferProgress>[];
    await useCase.send(
      localNodeId: 'node-a',
      destinationNodeId: 'node-b',
      fileName: 'notes.txt',
      bytes: Uint8List.fromList('hello world'.codeUnits),
      mimeType: 'text/plain',
      onProgress: progressEvents.add,
    );

    expect(progressEvents, hasLength(3));
    expect(progressEvents.first.processedChunks, 1);
    expect(progressEvents.first.totalChunks, 3);
    expect(progressEvents.first.currentChunkIndex, 0);
    expect(progressEvents.last.processedChunks, 3);
    expect(progressEvents.last.fractionComplete, closeTo(1.0, 0.000001));
  });

  test(
    'send file transfer throws when content store quota is exceeded',
    () async {
      final fakeBundles = _FakeBundleRepository();
      final fakeContentStore = _FakeContentStore(
        putError: const ContentStoreQuotaExceededException(
          maxBytes: 10,
          currentBytes: 10,
          requestedBytes: 1,
        ),
      );
      final prepare = PrepareBundleContentUseCase(
        bundles: fakeBundles,
        contentStore: fakeContentStore,
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000005000),
      );
      final useCase = SendFileTransferUseCase(
        bundles: fakeBundles,
        prepareBundleContent: prepare,
        bundleSignatureService: _FakeBundleSignatureService(),
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000006000),
        chunkSizeBytes: 4,
      );

      await expectLater(
        () => useCase.send(
          localNodeId: 'node-a',
          destinationNodeId: 'node-b',
          fileName: 'notes.txt',
          bytes: Uint8List.fromList('hello world'.codeUnits),
          mimeType: 'text/plain',
        ),
        throwsA(isA<ContentStoreQuotaExceededException>()),
      );
    },
  );
}

class _FakeContentStore implements ContentStore {
  _FakeContentStore({this.putError});

  final Exception? putError;

  @override
  Future<String?> put({
    required String contentHash,
    required Uint8List bytes,
  }) async {
    if (putError != null) {
      throw putError!;
    }
    return '/tmp/content/$contentHash';
  }

  @override
  Future<Uint8List?> read({required String contentHash}) async {
    return null;
  }
}

class _FakeBundleRepository implements BundleRepository {
  final List<Bundle> savedBundles = <Bundle>[];
  final Map<String, Bundle> _bundlesById = <String, Bundle>{};
  final List<ContentMetadataRecord> savedMetadata = <ContentMetadataRecord>[];

  @override
  Future<void> save(Bundle bundle) async {
    savedBundles.add(bundle);
    _bundlesById[bundle.bundleId] = bundle;
  }

  @override
  Future<Bundle?> getById(String bundleId) async {
    return _bundlesById[bundleId];
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
  Future<void> markAcknowledged(String bundleId) async {}

  @override
  Future<void> markRejected(String bundleId, {required String reason}) async {}

  @override
  Future<void> markSendFailed(
    String bundleId, {
    required String errorMessage,
  }) async {}

  @override
  Future<void> markSent(String bundleId) async {}

  @override
  Future<bool> recordAckReceipt(Bundle ackBundle) async => false;

  @override
  Future<List<Bundle>> getPendingBundles() async => const <Bundle>[];

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
