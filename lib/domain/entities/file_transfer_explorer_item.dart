import 'dart:convert';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';

enum FileTransferKind { image, pdf, video, audio, text, archive, unknown }

enum FileTransferStatus { complete, partial, failed }

class FileTransferExplorerItem {
  const FileTransferExplorerItem({
    required this.contentHash,
    required this.fileName,
    required this.mimeType,
    required this.kind,
    required this.destinationNodeId,
    required this.sourceNodeId,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.totalBytes,
    required this.expectedChunkCount,
    required this.chunkBundleIdsByIndex,
    required this.metadataBundleId,
    required this.localPath,
    required this.failedBundleCount,
    required this.lastError,
  });

  final String contentHash;
  final String? fileName;
  final String? mimeType;
  final FileTransferKind kind;
  final String? destinationNodeId;
  final String? sourceNodeId;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final int? totalBytes;
  final int? expectedChunkCount;
  final Map<int, String> chunkBundleIdsByIndex;
  final String? metadataBundleId;
  final String? localPath;
  final int failedBundleCount;
  final String? lastError;

  String get displayName =>
      fileName?.trim().isNotEmpty == true ? fileName!.trim() : contentHash;

  String get destinationLabel => destinationNodeId ?? 'Broadcast';

  List<int> get receivedChunkIndices {
    final indices = chunkBundleIdsByIndex.keys.toList(growable: false)..sort();
    return indices;
  }

  int get availableChunkCount => chunkBundleIdsByIndex.length;

  bool get hasExpectedChunkCount => (expectedChunkCount ?? 0) > 0;

  bool get isComplete {
    final expected = expectedChunkCount ?? 0;
    if (expected <= 0) {
      return availableChunkCount > 0;
    }
    return availableChunkCount >= expected;
  }

  bool get isFailed => failedBundleCount > 0;

  FileTransferStatus get status {
    if (isFailed) {
      return FileTransferStatus.failed;
    }
    if (isComplete) {
      return FileTransferStatus.complete;
    }
    return FileTransferStatus.partial;
  }

  String get statusLabel {
    return switch (status) {
      FileTransferStatus.complete => 'Complete',
      FileTransferStatus.partial => 'Partial',
      FileTransferStatus.failed => 'Failed',
    };
  }

  double get completionFraction {
    final expected = expectedChunkCount ?? 0;
    if (expected <= 0) {
      return availableChunkCount == 0 ? 0 : 1;
    }
    return (availableChunkCount / expected).clamp(0, 1);
  }

  String get chunkSummary {
    final expected = expectedChunkCount;
    if (expected == null || expected <= 0) {
      return '$availableChunkCount chunk${availableChunkCount == 1 ? '' : 's'} seen';
    }
    return '$availableChunkCount/$expected chunks';
  }
}

List<FileTransferExplorerItem> buildFileTransferExplorerItems({
  required List<Bundle> bundles,
  required List<ContentMetadataRecord> contentMetadata,
}) {
  final Map<String, ContentMetadataRecord> metadataByHash =
      <String, ContentMetadataRecord>{
        for (final record in contentMetadata) record.contentHash: record,
      };

  final Map<String, _FileTransferBuilder> builders =
      <String, _FileTransferBuilder>{};

  for (final bundle in bundles) {
    if (bundle.type == Bundle.typeFileShareMetadata) {
      final payload = _decodeObjectPayload(bundle.payload);
      final contentHash = _contentHashFromBundle(bundle, payload);
      if (contentHash == null || contentHash.isEmpty) {
        continue;
      }

      final builder = builders.putIfAbsent(
        contentHash,
        () => _FileTransferBuilder(contentHash: contentHash),
      );
      builder.absorbMetadataBundle(bundle, payload);
      continue;
    }

    if (bundle.type == Bundle.typeFileShareChunk) {
      final payload = _decodeObjectPayload(bundle.payload);
      final contentHash = _contentHashFromBundle(bundle, payload);
      if (contentHash == null || contentHash.isEmpty) {
        continue;
      }

      final builder = builders.putIfAbsent(
        contentHash,
        () => _FileTransferBuilder(contentHash: contentHash),
      );
      builder.absorbChunkBundle(bundle, payload);
    }
  }

  for (final record in contentMetadata) {
    final builder = builders.putIfAbsent(
      record.contentHash,
      () => _FileTransferBuilder(contentHash: record.contentHash),
    );
    builder.absorbContentMetadata(record);
  }

  final items = builders.values
      .map((builder) {
        final metadata = metadataByHash[builder.contentHash];
        return builder.build(metadata);
      })
      .toList(growable: false);

  items.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
  return items;
}

Map<String, Object?>? _decodeObjectPayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    return null;
  }

  try {
    final Object? parsed = jsonDecode(payload);
    if (parsed is! Map) {
      return null;
    }
    return parsed.cast<String, Object?>();
  } catch (_) {
    return null;
  }
}

String? _contentHashFromBundle(Bundle bundle, Map<String, Object?>? payload) {
  final payloadReference = bundle.payloadReference;
  if (payloadReference != null && payloadReference.isNotEmpty) {
    return payloadReference;
  }

  final dynamic contentHashFromPayload = payload?['contentHash'];
  if (contentHashFromPayload is String && contentHashFromPayload.isNotEmpty) {
    return contentHashFromPayload;
  }

  return null;
}

FileTransferKind fileTransferKindFromMimeType(String? mimeType) {
  final normalized = mimeType?.toLowerCase().trim();
  if (normalized == null || normalized.isEmpty) {
    return FileTransferKind.unknown;
  }

  if (normalized.startsWith('image/')) {
    return FileTransferKind.image;
  }
  if (normalized == 'application/pdf') {
    return FileTransferKind.pdf;
  }
  if (normalized.startsWith('video/')) {
    return FileTransferKind.video;
  }
  if (normalized.startsWith('audio/')) {
    return FileTransferKind.audio;
  }
  if (normalized.startsWith('text/')) {
    return FileTransferKind.text;
  }
  if (normalized.contains('zip') ||
      normalized.contains('compressed') ||
      normalized.contains('archive')) {
    return FileTransferKind.archive;
  }
  return FileTransferKind.unknown;
}

class _FileTransferBuilder {
  _FileTransferBuilder({required this.contentHash});

  final String contentHash;
  String? fileName;
  String? mimeType;
  String? destinationNodeId;
  String? sourceNodeId;
  DateTime? createdAt;
  DateTime? lastUpdatedAt;
  int? totalBytes;
  int? expectedChunkCount;
  String? metadataBundleId;
  String? localPath;
  int failedBundleCount = 0;
  String? lastError;
  final Map<int, String> chunkBundleIdsByIndex = <int, String>{};

  void absorbMetadataBundle(Bundle bundle, Map<String, Object?>? payload) {
    metadataBundleId = bundle.bundleId;
    destinationNodeId ??= bundle.destinationNodeId;
    sourceNodeId ??= bundle.sourceNodeId;
    createdAt = _pickEarliest(createdAt, bundle.createdAt);
    lastUpdatedAt = _pickLatest(lastUpdatedAt, bundle.createdAt);
    _absorbFailure(bundle);

    fileName ??= _stringField(payload, 'fileName');
    mimeType ??= _stringField(payload, 'mimeType');
    totalBytes ??= _intField(payload, 'sizeBytes');
    expectedChunkCount ??= _intField(payload, 'chunkCount');

    final dynamic explicitContentHash = payload?['contentHash'];
    if (explicitContentHash is String && explicitContentHash.isNotEmpty) {
      fileName ??= _stringField(payload, 'fileName');
    }
  }

  void absorbChunkBundle(Bundle bundle, Map<String, Object?>? payload) {
    destinationNodeId ??= bundle.destinationNodeId;
    sourceNodeId ??= bundle.sourceNodeId;
    createdAt = _pickEarliest(createdAt, bundle.createdAt);
    lastUpdatedAt = _pickLatest(lastUpdatedAt, bundle.createdAt);
    _absorbFailure(bundle);

    fileName ??= _stringField(payload, 'fileName');
    mimeType ??= _stringField(payload, 'mimeType');
    totalBytes ??= _intField(payload, 'totalBytes');
    expectedChunkCount ??= _intField(payload, 'chunkCount');

    final chunkIndex = _intField(payload, 'chunkIndex');
    if (chunkIndex != null) {
      chunkBundleIdsByIndex[chunkIndex] = bundle.bundleId;
    }
  }

  void absorbContentMetadata(ContentMetadataRecord record) {
    createdAt = _pickEarliest(createdAt, record.createdAt);
    lastUpdatedAt = _pickLatest(lastUpdatedAt, record.createdAt);
    mimeType ??= record.mimeType;
    totalBytes ??= record.totalBytes;
    expectedChunkCount ??= record.chunkCount;
    localPath ??= record.localPath;
  }

  FileTransferExplorerItem build(ContentMetadataRecord? metadata) {
    final effectiveMimeType = mimeType ?? metadata?.mimeType;
    final effectiveTotalBytes = totalBytes ?? metadata?.totalBytes;
    final effectiveExpectedCount = expectedChunkCount ?? metadata?.chunkCount;

    return FileTransferExplorerItem(
      contentHash: contentHash,
      fileName: fileName,
      mimeType: effectiveMimeType,
      kind: fileTransferKindFromMimeType(effectiveMimeType),
      destinationNodeId: destinationNodeId,
      sourceNodeId: sourceNodeId,
      createdAt:
          createdAt ??
          metadata?.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastUpdatedAt:
          lastUpdatedAt ??
          metadata?.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
      totalBytes: effectiveTotalBytes,
      expectedChunkCount: effectiveExpectedCount,
      chunkBundleIdsByIndex: Map<int, String>.unmodifiable(
        chunkBundleIdsByIndex,
      ),
      metadataBundleId: metadataBundleId,
      localPath: localPath ?? metadata?.localPath,
      failedBundleCount: failedBundleCount,
      lastError: lastError,
    );
  }

  void _absorbFailure(Bundle bundle) {
    final error = bundle.lastError;
    if (error == null || error.isEmpty) {
      return;
    }
    failedBundleCount += 1;
    lastError = error;
  }

  DateTime? _pickLatest(DateTime? current, DateTime candidate) {
    if (current == null || candidate.isAfter(current)) {
      return candidate;
    }
    return current;
  }

  DateTime? _pickEarliest(DateTime? current, DateTime candidate) {
    if (current == null || candidate.isBefore(current)) {
      return candidate;
    }
    return current;
  }

  String? _stringField(Map<String, Object?>? payload, String key) {
    final dynamic value = payload?[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  int? _intField(Map<String, Object?>? payload, String key) {
    final dynamic value = payload?[key];
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
