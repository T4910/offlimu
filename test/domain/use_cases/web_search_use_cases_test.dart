import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/web_search_result.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/use_cases/prepare_bundle_content_use_case.dart';
import 'package:offlimu/domain/use_cases/send_file_transfer_use_case.dart';
import 'package:offlimu/domain/use_cases/submit_web_search_request_use_case.dart';
import 'package:offlimu/domain/use_cases/web_search_result_ingestion_service.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';
import 'package:offlimu/infrastructure/db/drift_web_search_repository.dart';

void main() {
  test('submit web search creates a signed broadcast request bundle', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final bundleRepository = DriftBundleRepository(db, localNodeId: 'node-a');
    final useCase = SubmitWebSearchRequestUseCase(
      bundles: bundleRepository,
      bundleSignatureService: _PassThroughSignatureService(),
      now: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    final bundle = await useCase.submit(
      localNodeId: 'node-a',
      query: 'mesh routing',
    );

    expect(bundle.type, Bundle.typeWebSearchRequest);
    expect(bundle.appId, 'offlimu.web');
    expect(bundle.destinationNodeId, isNull);
    expect(bundle.destinationScope, BundleDestinationScope.broadcast);
    expect(bundle.priority, BundlePriority.high);
    expect(bundle.payload, contains('mesh routing'));

    final saved = await bundleRepository.getById(bundle.bundleId);
    expect(saved, isNotNull);
  });

  test(
    'submit web search reuses an active request for the same query',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final bundleRepository = DriftBundleRepository(db, localNodeId: 'node-a');
      final useCase = SubmitWebSearchRequestUseCase(
        bundles: bundleRepository,
        bundleSignatureService: _PassThroughSignatureService(),
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final first = await useCase.submit(
        localNodeId: 'node-a',
        query: 'mesh   routing',
      );
      final second = await useCase.submit(
        localNodeId: 'node-a',
        query: 'Mesh Routing',
      );

      final requests = (await bundleRepository.getAllBundles())
          .where((bundle) => bundle.type == Bundle.typeWebSearchRequest)
          .toList(growable: false);

      expect(second.bundleId, first.bundleId);
      expect(requests, hasLength(1));
    },
  );

  test(
    'ingest mock web results creates web file bundles and index update',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final bundleRepository = DriftBundleRepository(db, localNodeId: 'node-a');
      final webRepository = DriftWebSearchRepository(db);
      final contentStore = _MemoryContentStore();
      final prepare = PrepareBundleContentUseCase(
        bundles: bundleRepository,
        contentStore: contentStore,
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      final sendFileTransfer = SendFileTransferUseCase(
        bundles: bundleRepository,
        prepareBundleContent: prepare,
        bundleSignatureService: _PassThroughSignatureService(),
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000001000),
        chunkSizeBytes: 64,
      );
      final ingestion = WebSearchResultIngestionService(
        sendFileTransfer: sendFileTransfer,
        webSearchRepository: webRepository,
        bundleRepository: bundleRepository,
        bundleSignatureService: _PassThroughSignatureService(),
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000002000),
      );

      await ingestion.ingest(
        localNodeId: 'node-a',
        results: const <WebSearchResult>[
          WebSearchResult(
            requestBundleId: 'request-1',
            query: 'mesh',
            title: 'Mesh result',
            url: 'https://example.test/mesh',
            snippet: 'A cached page about mesh routing.',
            html: '<html><body>mesh</body></html>',
          ),
        ],
      );

      final bundles = await bundleRepository.getAllBundles();
      expect(
        bundles.where((bundle) => bundle.type == Bundle.typeFileShareMetadata),
        hasLength(1),
      );
      expect(
        bundles.where((bundle) => bundle.type == Bundle.typeFileShareChunk),
        hasLength(1),
      );
      expect(
        bundles.where((bundle) => bundle.type == Bundle.typeWebIndexUpdate),
        hasLength(1),
      );
      expect(bundles.every((bundle) => bundle.appId == 'offlimu.web'), isTrue);

      final results = await webRepository.search('mesh');
      expect(results, hasLength(1));
      expect(results.single.isComplete, isTrue);
    },
  );
}

class _PassThroughSignatureService implements BundleSignatureService {
  @override
  Future<Bundle> sign({required Bundle bundle, required String nodeId}) async {
    return bundle.copyWith(signature: 'signed-by-$nodeId');
  }

  @override
  Future<bool> verify(Bundle bundle) async => true;
}

class _MemoryContentStore implements ContentStore {
  final Map<String, Uint8List> _bytesByHash = <String, Uint8List>{};

  @override
  Future<String?> put({
    required String contentHash,
    required Uint8List bytes,
  }) async {
    _bytesByHash[contentHash] = bytes;
    return '/tmp/$contentHash.html';
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
