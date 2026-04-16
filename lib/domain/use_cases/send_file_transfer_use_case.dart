import 'dart:convert';
import 'dart:typed_data';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/use_cases/prepare_bundle_content_use_case.dart';

class FileTransferDispatchResult {
  const FileTransferDispatchResult({
    required this.contentHash,
    required this.chunkCount,
    required this.manifestBundle,
  });

  final String contentHash;
  final int chunkCount;
  final Bundle manifestBundle;
}

class FileTransferProgress {
  const FileTransferProgress({
    required this.processedChunks,
    required this.totalChunks,
    required this.currentChunkIndex,
    required this.skipped,
  });

  final int processedChunks;
  final int totalChunks;
  final int currentChunkIndex;
  final bool skipped;

  double get fractionComplete {
    if (totalChunks <= 0) {
      return 0;
    }
    return processedChunks / totalChunks;
  }
}

class SendFileTransferUseCase {
  SendFileTransferUseCase({
    required BundleRepository bundles,
    required PrepareBundleContentUseCase prepareBundleContent,
    required BundleSignatureService bundleSignatureService,
    DateTime Function()? now,
    this.chunkSizeBytes = 128 * 1024,
  }) : _bundles = bundles,
       _prepareBundleContent = prepareBundleContent,
       _bundleSignatureService = bundleSignatureService,
       _now = now ?? DateTime.now;

  final BundleRepository _bundles;
  final PrepareBundleContentUseCase _prepareBundleContent;
  final BundleSignatureService _bundleSignatureService;
  final DateTime Function() _now;
  final int chunkSizeBytes;

  Future<FileTransferDispatchResult> send({
    required String localNodeId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? destinationNodeId,
    BundlePriority priority = BundlePriority.normal,
    int ttlSeconds = 3600,
    String appId = 'offlimu.files',
    void Function(FileTransferProgress progress)? onProgress,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('File bytes must not be empty.');
    }
    if (chunkSizeBytes <= 0) {
      throw ArgumentError('chunkSizeBytes must be greater than zero.');
    }

    final DateTime createdAt = _now();
    final Bundle metadataBundle = Bundle(
      bundleId: 'file-meta-${createdAt.microsecondsSinceEpoch}',
      type: Bundle.typeFileShareMetadata,
      sourceNodeId: localNodeId,
      destinationNodeId: destinationNodeId,
      destinationScope: destinationNodeId == null
          ? BundleDestinationScope.broadcast
          : BundleDestinationScope.direct,
      priority: priority,
      payload: jsonEncode(<String, Object?>{
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': bytes.length,
        'chunkSizeBytes': chunkSizeBytes,
      }),
      appId: appId,
      createdAt: createdAt,
      ttlSeconds: ttlSeconds,
    );

    final Bundle prepared = await _prepareBundleContent.attachBytes(
      bundle: metadataBundle,
      bytes: bytes,
      mimeType: mimeType,
    );

    final String contentHash =
        prepared.payloadReference ?? (throw StateError('Missing content hash'));
    final int chunkCount =
        (bytes.length + chunkSizeBytes - 1) ~/ chunkSizeBytes;
    final String transferKey = _transferKey(destinationNodeId);

    final ContentMetadataRecord? existingMetadata = await _bundles
        .getContentMetadata(contentHash);
    await _bundles.saveContentMetadata(
      ContentMetadataRecord(
        contentHash: contentHash,
        mimeType: mimeType,
        totalBytes: bytes.length,
        chunkCount: chunkCount,
        createdAt: existingMetadata?.createdAt ?? createdAt,
        localPath: existingMetadata?.localPath,
      ),
    );

    final Bundle manifestBundle = prepared.copyWith(
      bundleId: 'file-meta-$transferKey-$contentHash',
      payload: jsonEncode(<String, Object?>{
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': bytes.length,
        'chunkSizeBytes': chunkSizeBytes,
        'chunkCount': chunkCount,
        'contentHash': contentHash,
      }),
    );

    final Bundle signedManifest = await _bundleSignatureService.sign(
      bundle: manifestBundle,
      nodeId: localNodeId,
    );

    final Bundle? existingManifest = await _bundles.getById(
      signedManifest.bundleId,
    );
    if (existingManifest == null) {
      await _bundles.save(signedManifest);
    }

    var processedChunks = 0;
    for (var index = 0; index < chunkCount; index++) {
      final int start = index * chunkSizeBytes;
      final int end = start + chunkSizeBytes > bytes.length
          ? bytes.length
          : start + chunkSizeBytes;
      final Uint8List chunkBytes = Uint8List.fromList(
        bytes.sublist(start, end),
      );
      final Bundle chunkBundle = Bundle(
        bundleId: 'file-chunk-$transferKey-$contentHash-$index',
        type: Bundle.typeFileShareChunk,
        sourceNodeId: localNodeId,
        destinationNodeId: destinationNodeId,
        destinationScope: destinationNodeId == null
            ? BundleDestinationScope.broadcast
            : BundleDestinationScope.direct,
        priority: priority,
        payloadReference: contentHash,
        payload: jsonEncode(<String, Object?>{
          'contentHash': contentHash,
          'fileName': fileName,
          'mimeType': mimeType,
          'chunkIndex': index,
          'chunkCount': chunkCount,
          'totalBytes': bytes.length,
          'chunkBytesBase64': base64Encode(chunkBytes),
        }),
        appId: appId,
        createdAt: createdAt,
        ttlSeconds: ttlSeconds,
      );
      final Bundle signedChunk = await _bundleSignatureService.sign(
        bundle: chunkBundle,
        nodeId: localNodeId,
      );
      final Bundle? existingChunk = await _bundles.getById(
        signedChunk.bundleId,
      );
      bool skipped = false;
      if (existingChunk == null) {
        await _bundles.save(signedChunk);
      } else {
        skipped = true;
      }
      processedChunks += 1;
      onProgress?.call(
        FileTransferProgress(
          processedChunks: processedChunks,
          totalChunks: chunkCount,
          currentChunkIndex: index,
          skipped: skipped,
        ),
      );
    }

    return FileTransferDispatchResult(
      contentHash: contentHash,
      chunkCount: chunkCount,
      manifestBundle: signedManifest,
    );
  }

  String _transferKey(String? destinationNodeId) {
    return destinationNodeId ?? 'broadcast';
  }
}
