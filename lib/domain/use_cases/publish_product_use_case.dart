import 'dart:convert';
import 'dart:typed_data';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/commerce_product.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/commerce_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/use_cases/send_file_transfer_use_case.dart';

class PublishProductUseCase {
  PublishProductUseCase({
    required SendFileTransferUseCase sendFileTransfer,
    required BundleRepository bundleRepository,
    required CommerceRepository commerceRepository,
    required BundleSignatureService bundleSignatureService,
    DateTime Function()? now,
  }) : _sendFileTransfer = sendFileTransfer,
       _bundleRepository = bundleRepository,
       _commerceRepository = commerceRepository,
       _bundleSignatureService = bundleSignatureService,
       _now = now ?? DateTime.now;

  static const String commerceAppId = 'offlimu.commerce';

  final SendFileTransferUseCase _sendFileTransfer;
  final BundleRepository _bundleRepository;
  final CommerceRepository _commerceRepository;
  final BundleSignatureService _bundleSignatureService;
  final DateTime Function() _now;

  Future<CommerceProduct> publish({
    required String localNodeId,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String imageFileName,
    required Uint8List imageBytes,
    required String imageMimeType,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError('Product title must not be empty.');
    }
    if (normalizedDescription.isEmpty) {
      throw ArgumentError('Product description must not be empty.');
    }
    if (priceMinorUnits <= 0) {
      throw ArgumentError('Product price must be greater than zero.');
    }
    if (!imageMimeType.toLowerCase().startsWith('image/')) {
      throw ArgumentError('Product image must be an image file.');
    }

    final now = _now();
    final transfer = await _sendFileTransfer.send(
      localNodeId: localNodeId,
      fileName: imageFileName,
      bytes: imageBytes,
      mimeType: imageMimeType,
      destinationNodeId: null,
      priority: BundlePriority.high,
      ttlSeconds: 86400,
      appId: commerceAppId,
    );
    final productId = 'product-$localNodeId-${now.microsecondsSinceEpoch}';
    final payload = jsonEncode(<String, Object?>{
      'productId': productId,
      'title': normalizedTitle,
      'description': normalizedDescription,
      'vendorNodeId': localNodeId,
      'priceMinorUnits': priceMinorUnits,
      'imageContentHash': transfer.contentHash,
      'imageMimeType': imageMimeType,
      'createdAtMs': now.millisecondsSinceEpoch,
      'updatedAtMs': now.millisecondsSinceEpoch,
    });
    final bundle = Bundle(
      bundleId: 'commerce-product-${now.microsecondsSinceEpoch}',
      type: Bundle.typeCommerceProductUpsert,
      sourceNodeId: localNodeId,
      destinationNodeId: null,
      destinationScope: BundleDestinationScope.broadcast,
      priority: BundlePriority.high,
      payload: payload,
      appId: commerceAppId,
      createdAt: now,
      ttlSeconds: 86400,
    );
    final signed = await _bundleSignatureService.sign(
      bundle: bundle,
      nodeId: localNodeId,
    );
    await _bundleRepository.save(signed);
    final draft = CommerceProductDraft(
      productId: productId,
      title: normalizedTitle,
      description: normalizedDescription,
      vendorNodeId: localNodeId,
      priceMinorUnits: priceMinorUnits,
      imageContentHash: transfer.contentHash,
      imageMimeType: imageMimeType,
      availability: CommerceProductAvailability.available,
      createdAt: now,
      updatedAt: now,
      sourceBundleId: signed.bundleId,
    );
    await _commerceRepository.saveLocalProduct(draft);
    return (await _commerceRepository.getProduct(productId))!;
  }
}
