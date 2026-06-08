import 'dart:convert';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/commerce_order.dart';
import 'package:offlimu/domain/entities/commerce_product.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/commerce_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/use_cases/initiate_wallet_spend_use_case.dart';
import 'package:offlimu/domain/use_cases/publish_product_use_case.dart';

class MarkOrderReceivedUseCase {
  MarkOrderReceivedUseCase({
    required CommerceRepository commerceRepository,
    required BundleRepository bundleRepository,
    required BundleSignatureService bundleSignatureService,
    DateTime Function()? now,
  }) : _commerceRepository = commerceRepository,
       _bundleRepository = bundleRepository,
       _bundleSignatureService = bundleSignatureService,
       _now = now ?? DateTime.now;

  final CommerceRepository _commerceRepository;
  final BundleRepository _bundleRepository;
  final BundleSignatureService _bundleSignatureService;
  final DateTime Function() _now;

  Future<void> markReceived({
    required String localNodeId,
    required CommerceOrder order,
  }) async {
    if (order.vendorNodeId != localNodeId) {
      throw StateError('Only the vendor can receive this order.');
    }
    final now = _now();
    final bundle = Bundle(
      bundleId: 'commerce-order-received-${now.microsecondsSinceEpoch}',
      type: Bundle.typeCommerceOrderReceived,
      sourceNodeId: localNodeId,
      destinationNodeId: order.buyerNodeId,
      destinationScope: BundleDestinationScope.direct,
      priority: BundlePriority.high,
      payload: jsonEncode(<String, Object?>{
        'orderId': order.orderId,
        'vendorNodeId': localNodeId,
        'buyerNodeId': order.buyerNodeId,
        'updatedAtMs': now.millisecondsSinceEpoch,
      }),
      appId: PublishProductUseCase.commerceAppId,
      createdAt: now,
      ttlSeconds: 86400,
    );
    final signed = await _bundleSignatureService.sign(
      bundle: bundle,
      nodeId: localNodeId,
    );
    await _bundleRepository.save(signed);
    await _commerceRepository.markLocalOrderStatus(
      orderId: order.orderId,
      status: CommerceOrderStatus.received,
      updatedAt: now,
      statusBundleId: signed.bundleId,
    );
  }
}

class RejectCommerceOrderUseCase {
  RejectCommerceOrderUseCase({
    required CommerceRepository commerceRepository,
    required BundleRepository bundleRepository,
    required InitiateWalletSpendUseCase initiateWalletSpend,
    required BundleSignatureService bundleSignatureService,
    DateTime Function()? now,
  }) : _commerceRepository = commerceRepository,
       _bundleRepository = bundleRepository,
       _initiateWalletSpend = initiateWalletSpend,
       _bundleSignatureService = bundleSignatureService,
       _now = now ?? DateTime.now;

  final CommerceRepository _commerceRepository;
  final BundleRepository _bundleRepository;
  final InitiateWalletSpendUseCase _initiateWalletSpend;
  final BundleSignatureService _bundleSignatureService;
  final DateTime Function() _now;

  Future<void> reject({
    required String localNodeId,
    required CommerceOrder order,
    required String reason,
  }) async {
    if (order.vendorNodeId != localNodeId) {
      throw StateError('Only the vendor can reject this order.');
    }
    final now = _now();
    String? refundBundleId;
    if (order.paymentBundleId != null) {
      final refund = await _initiateWalletSpend.initiate(
        localNodeId: localNodeId,
        recipientNodeId: order.buyerNodeId,
        amountMinorUnits: order.priceMinorUnits,
        memo: 'Refund for commerce order ${order.orderId}',
        ttlSeconds: 86400,
      );
      refundBundleId = refund.bundle.bundleId;
    }
    final normalizedReason = reason.trim().isEmpty
        ? 'Order rejected by vendor'
        : reason.trim();
    final bundle = Bundle(
      bundleId: 'commerce-order-rejected-${now.microsecondsSinceEpoch}',
      type: Bundle.typeCommerceOrderRejected,
      sourceNodeId: localNodeId,
      destinationNodeId: order.buyerNodeId,
      destinationScope: BundleDestinationScope.direct,
      priority: BundlePriority.high,
      payload: jsonEncode(<String, Object?>{
        'orderId': order.orderId,
        'vendorNodeId': localNodeId,
        'buyerNodeId': order.buyerNodeId,
        'reason': normalizedReason,
        'refundBundleId': refundBundleId,
        'updatedAtMs': now.millisecondsSinceEpoch,
      }),
      appId: PublishProductUseCase.commerceAppId,
      createdAt: now,
      ttlSeconds: 86400,
    );
    final signed = await _bundleSignatureService.sign(
      bundle: bundle,
      nodeId: localNodeId,
    );
    await _bundleRepository.save(signed);
    await _commerceRepository.markLocalOrderStatus(
      orderId: order.orderId,
      status: CommerceOrderStatus.rejected,
      updatedAt: now,
      statusBundleId: signed.bundleId,
      refundBundleId: refundBundleId,
      rejectionReason: normalizedReason,
    );
  }
}

class MarkProductOutOfStockUseCase {
  MarkProductOutOfStockUseCase({
    required CommerceRepository commerceRepository,
    required BundleRepository bundleRepository,
    required RejectCommerceOrderUseCase rejectOrder,
    required BundleSignatureService bundleSignatureService,
    DateTime Function()? now,
  }) : _commerceRepository = commerceRepository,
       _bundleRepository = bundleRepository,
       _rejectOrder = rejectOrder,
       _bundleSignatureService = bundleSignatureService,
       _now = now ?? DateTime.now;

  final CommerceRepository _commerceRepository;
  final BundleRepository _bundleRepository;
  final RejectCommerceOrderUseCase _rejectOrder;
  final BundleSignatureService _bundleSignatureService;
  final DateTime Function() _now;

  Future<void> markOutOfStock({
    required String localNodeId,
    required CommerceProduct product,
    required bool rejectOpenOrders,
  }) async {
    if (product.vendorNodeId != localNodeId) {
      throw StateError('Only the vendor can update this product.');
    }

    final openOrders = await _commerceRepository
        .getOpenIncomingOrdersForProduct(
          localNodeId: localNodeId,
          productId: product.productId,
        );
    if (openOrders.isNotEmpty && !rejectOpenOrders) {
      throw StateError(
        'Open orders must be rejected before marking out of stock.',
      );
    }
    for (final order in openOrders) {
      await _rejectOrder.reject(
        localNodeId: localNodeId,
        order: order,
        reason: 'Product is out of stock',
      );
    }

    final now = _now();
    final bundle = Bundle(
      bundleId: 'commerce-product-out-${now.microsecondsSinceEpoch}',
      type: Bundle.typeCommerceProductOutOfStock,
      sourceNodeId: localNodeId,
      destinationNodeId: null,
      destinationScope: BundleDestinationScope.broadcast,
      priority: BundlePriority.high,
      payload: jsonEncode(<String, Object?>{
        'productId': product.productId,
        'vendorNodeId': localNodeId,
        'updatedAtMs': now.millisecondsSinceEpoch,
      }),
      appId: PublishProductUseCase.commerceAppId,
      createdAt: now,
      ttlSeconds: 86400,
    );
    final signed = await _bundleSignatureService.sign(
      bundle: bundle,
      nodeId: localNodeId,
    );
    await _bundleRepository.save(signed);
    await _commerceRepository.saveLocalProduct(
      CommerceProductDraft(
        productId: product.productId,
        title: product.title,
        description: product.description,
        vendorNodeId: product.vendorNodeId,
        priceMinorUnits: product.priceMinorUnits,
        imageContentHash: product.imageContentHash,
        imageMimeType: product.imageMimeType,
        availability: CommerceProductAvailability.outOfStock,
        createdAt: product.createdAt,
        updatedAt: now,
        sourceBundleId: signed.bundleId,
      ),
    );
  }
}
