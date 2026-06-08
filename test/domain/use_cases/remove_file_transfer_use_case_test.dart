import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/use_cases/remove_file_transfer_use_case.dart';

void main() {
  test(
    'remove deletes local file bundles, metadata, and cached bytes',
    () async {
      final contentHash = 'sha256:file';
      final bundles = _MemoryBundleRepository(
        bundles: <Bundle>[
          Bundle(
            bundleId: 'meta-1',
            type: Bundle.typeFileShareMetadata,
            sourceNodeId: 'node-a',
            payloadReference: contentHash,
            payload: jsonEncode(<String, Object?>{
              'contentHash': contentHash,
              'fileName': 'report.pdf',
            }),
            createdAt: DateTime(2026),
            ttlSeconds: 3600,
          ),
          Bundle(
            bundleId: 'chunk-1',
            type: Bundle.typeFileShareChunk,
            sourceNodeId: 'node-a',
            payloadReference: contentHash,
            payload: jsonEncode(<String, Object?>{
              'contentHash': contentHash,
              'chunkIndex': 0,
            }),
            createdAt: DateTime(2026),
            ttlSeconds: 3600,
          ),
          Bundle(
            bundleId: 'chat-1',
            type: Bundle.typeChatMessage,
            sourceNodeId: 'node-a',
            payload: 'keep me',
            createdAt: DateTime(2026),
            ttlSeconds: 3600,
          ),
        ],
        metadata: <ContentMetadataRecord>[
          ContentMetadataRecord(
            contentHash: contentHash,
            totalBytes: 10,
            createdAt: DateTime(2026),
            localPath: '/tmp/file',
          ),
        ],
      );
      final contentStore = _MemoryContentStore(
        initialBytes: <String, Uint8List>{
          contentHash: Uint8List.fromList(<int>[1, 2, 3]),
        },
      );
      final useCase = RemoveFileTransferUseCase(
        bundles: bundles,
        contentStore: contentStore,
      );

      final result = await useCase.remove(contentHash);

      expect(result.deletedBundleCount, 2);
      expect(await bundles.getById('meta-1'), isNull);
      expect(await bundles.getById('chunk-1'), isNull);
      expect(await bundles.getById('chat-1'), isNotNull);
      expect(await bundles.getContentMetadata(contentHash), isNull);
      expect(await contentStore.read(contentHash: contentHash), isNull);
    },
  );
}

class _MemoryContentStore implements ContentStore {
  _MemoryContentStore({required Map<String, Uint8List> initialBytes})
    : _bytesByHash = Map<String, Uint8List>.from(initialBytes);

  final Map<String, Uint8List> _bytesByHash;

  @override
  Future<String?> put({
    required String contentHash,
    required Uint8List bytes,
  }) async {
    _bytesByHash[contentHash] = bytes;
    return '/tmp/$contentHash';
  }

  @override
  Future<Uint8List?> read({required String contentHash}) async {
    return _bytesByHash[contentHash];
  }

  @override
  Future<void> delete({required String contentHash}) async {
    _bytesByHash.remove(contentHash);
  }

  @override
  Future<void> clear() async {
    _bytesByHash.clear();
  }
}

class _MemoryBundleRepository implements BundleRepository {
  _MemoryBundleRepository({
    required List<Bundle> bundles,
    required List<ContentMetadataRecord> metadata,
  }) : _bundlesById = <String, Bundle>{
         for (final bundle in bundles) bundle.bundleId: bundle,
       },
       _metadataByHash = <String, ContentMetadataRecord>{
         for (final record in metadata) record.contentHash: record,
       };

  final Map<String, Bundle> _bundlesById;
  final Map<String, ContentMetadataRecord> _metadataByHash;

  @override
  Future<void> deleteBundle(String bundleId) async {
    _bundlesById.remove(bundleId);
  }

  @override
  Future<void> deleteContentMetadata(String contentHash) async {
    _metadataByHash.remove(contentHash);
  }

  @override
  Future<List<Bundle>> getAllBundles() async {
    return _bundlesById.values.toList(growable: false);
  }

  @override
  Future<Bundle?> getById(String bundleId) async => _bundlesById[bundleId];

  @override
  Future<ContentMetadataRecord?> getContentMetadata(String contentHash) async {
    return _metadataByHash[contentHash];
  }

  @override
  Future<void> save(Bundle bundle) async {
    _bundlesById[bundle.bundleId] = bundle;
  }

  @override
  Future<void> saveContentMetadata(ContentMetadataRecord metadata) async {
    _metadataByHash[metadata.contentHash] = metadata;
  }

  @override
  Future<List<Bundle>> getPendingBundles() async => const <Bundle>[];

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
  Future<void> resetForRetry(String bundleId) async {}

  @override
  Stream<List<Bundle>> watchAllBundles() => const Stream.empty();

  @override
  Stream<List<Bundle>> watchBundlesByType(String type) => const Stream.empty();

  @override
  Stream<List<Bundle>> watchPendingBundles() => const Stream.empty();

  @override
  Stream<List<AckAuditEvent>> watchRecentAckEvents({int limit = 20}) {
    return const Stream.empty();
  }

  @override
  Stream<List<ContentMetadataRecord>> watchRecentContentMetadata({
    int limit = 50,
  }) {
    return const Stream.empty();
  }
}
