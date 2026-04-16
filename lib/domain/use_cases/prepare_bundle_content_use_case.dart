import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/services/content_store.dart';

class PrepareBundleContentUseCase {
  PrepareBundleContentUseCase({
    required BundleRepository bundles,
    required ContentStore contentStore,
    DateTime Function()? now,
  }) : _bundles = bundles,
       _contentStore = contentStore,
       _now = now ?? DateTime.now;

  final BundleRepository _bundles;
  final ContentStore _contentStore;
  final DateTime Function() _now;

  Future<Bundle> attachUtf8Payload({
    required Bundle bundle,
    required String payload,
    String mimeType = 'text/plain; charset=utf-8',
  }) {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(payload));
    return attachBytes(bundle: bundle, bytes: bytes, mimeType: mimeType);
  }

  Future<Bundle> attachBytes({
    required Bundle bundle,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final String digest = sha256.convert(bytes).toString();
    final String contentHash = 'sha256:$digest';
    final String? localPath = await _contentStore.put(
      contentHash: contentHash,
      bytes: bytes,
    );

    await _bundles.saveContentMetadata(
      ContentMetadataRecord(
        contentHash: contentHash,
        mimeType: mimeType,
        totalBytes: bytes.length,
        createdAt: _now(),
        localPath: localPath,
      ),
    );

    return bundle.copyWith(payloadReference: contentHash);
  }
}
