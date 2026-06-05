import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/web_index_entry.dart';
import 'package:offlimu/domain/entities/web_search_result.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/web_search_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/use_cases/send_file_transfer_use_case.dart';

class WebSearchResultIngestionService {
  WebSearchResultIngestionService({
    required SendFileTransferUseCase sendFileTransfer,
    required WebSearchRepository webSearchRepository,
    required BundleRepository bundleRepository,
    required BundleSignatureService bundleSignatureService,
    DateTime Function()? now,
  }) : _sendFileTransfer = sendFileTransfer,
       _webSearchRepository = webSearchRepository,
       _bundleRepository = bundleRepository,
       _bundleSignatureService = bundleSignatureService,
       _now = now ?? DateTime.now;

  final SendFileTransferUseCase _sendFileTransfer;
  final WebSearchRepository _webSearchRepository;
  final BundleRepository _bundleRepository;
  final BundleSignatureService _bundleSignatureService;
  final DateTime Function() _now;

  Future<void> ingest({
    required String localNodeId,
    required List<WebSearchResult> results,
  }) async {
    if (results.isEmpty) {
      return;
    }

    final drafts = <WebIndexEntryDraft>[];
    for (final result in results) {
      final bytes = Uint8List.fromList(utf8.encode(result.html));
      final transfer = await _sendFileTransfer.send(
        localNodeId: localNodeId,
        fileName: _fileNameFor(result),
        bytes: bytes,
        mimeType: 'text/html; charset=utf-8',
        destinationNodeId: null,
        priority: BundlePriority.high,
        ttlSeconds: 86400,
        appId: 'offlimu.web',
      );
      drafts.add(
        WebIndexEntryDraft(
          contentHash: transfer.contentHash,
          title: result.title,
          url: result.url,
          snippet: result.snippet,
          query: result.query,
          sourceRequestId: result.requestBundleId,
          totalBytes: bytes.length,
          expectedChunkCount: transfer.chunkCount,
        ),
      );
    }

    await _webSearchRepository.upsertEntries(drafts);
    await _saveIndexUpdateBundle(
      localNodeId: localNodeId,
      sourceRequestId: results.first.requestBundleId,
      entries: drafts,
    );
  }

  Future<void> ingestIndexUpdateBundle(Bundle bundle) async {
    final entries = parseIndexUpdateBundle(bundle);
    await _webSearchRepository.upsertEntries(entries);
  }

  static List<WebIndexEntryDraft> parseIndexUpdateBundle(Bundle bundle) {
    final payload = bundle.payload;
    if (payload == null || payload.isEmpty) {
      return const <WebIndexEntryDraft>[];
    }
    final Object? parsed = jsonDecode(payload);
    if (parsed is! Map) {
      return const <WebIndexEntryDraft>[];
    }
    final Object? entriesRaw = parsed['entries'];
    if (entriesRaw is! List) {
      return const <WebIndexEntryDraft>[];
    }
    return entriesRaw
        .whereType<Map>()
        .map((raw) {
          final map = raw.cast<String, Object?>();
          return WebIndexEntryDraft(
            contentHash: map['contentHash'] as String? ?? '',
            title: map['title'] as String? ?? 'Offline page',
            url: map['url'] as String? ?? '',
            snippet: map['snippet'] as String? ?? '',
            query: map['query'] as String? ?? '',
            sourceRequestId: map['sourceRequestId'] as String? ?? '',
            totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
            expectedChunkCount:
                (map['expectedChunkCount'] as num?)?.toInt() ?? 1,
          );
        })
        .where((entry) => entry.contentHash.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _saveIndexUpdateBundle({
    required String localNodeId,
    required String sourceRequestId,
    required List<WebIndexEntryDraft> entries,
  }) async {
    final now = _now();
    final payload = jsonEncode(<String, Object?>{
      'sourceRequestId': sourceRequestId,
      'entries': entries
          .map((entry) {
            return <String, Object?>{
              'contentHash': entry.contentHash,
              'title': entry.title,
              'url': entry.url,
              'snippet': entry.snippet,
              'query': entry.query,
              'sourceRequestId': entry.sourceRequestId,
              'totalBytes': entry.totalBytes,
              'expectedChunkCount': entry.expectedChunkCount,
            };
          })
          .toList(growable: false),
    });
    final digest = sha256.convert(utf8.encode(payload)).toString();
    final bundle = Bundle(
      bundleId: 'web-index-$digest',
      type: Bundle.typeWebIndexUpdate,
      sourceNodeId: localNodeId,
      destinationNodeId: null,
      destinationScope: BundleDestinationScope.broadcast,
      priority: BundlePriority.high,
      payload: payload,
      appId: 'offlimu.web',
      createdAt: now,
      ttlSeconds: 86400,
    );
    final signed = await _bundleSignatureService.sign(
      bundle: bundle,
      nodeId: localNodeId,
    );
    final existing = await _bundleRepository.getById(signed.bundleId);
    if (existing == null) {
      await _bundleRepository.save(signed);
    }
  }

  String _fileNameFor(WebSearchResult result) {
    final base = result.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return '${base.isEmpty ? 'offline-page' : base}.html';
  }
}
