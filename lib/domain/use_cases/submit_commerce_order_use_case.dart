import 'dart:convert';

import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/commerce_order.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/commerce_repository.dart';
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/use_cases/initiate_wallet_spend_use_case.dart';
import 'package:offlimu/domain/use_cases/publish_product_use_case.dart';

class SubmitCommerceOrderUseCase {
  SubmitCommerceOrderUseCase({
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

  Future<CommerceOrder> submit({
    required String localNodeId,
    required String productId,
    required String details,
  }) async {
    final product = await _commerceRepository.getProduct(productId);
    if (product == null) {
      throw StateError('Product is not available locally.');
    }
    if (!product.isAvailable) {
      throw StateError('Product is out of stock.');
    }
    if (product.vendorNodeId == localNodeId) {
      throw StateError('You cannot order your own product.');
    }

    final now = _now();
    final orderId = 'order-$localNodeId-${now.microsecondsSinceEpoch}';
    final payment = await _initiateWalletSpend.initiate(
      localNodeId: localNodeId,
      recipientNodeId: product.vendorNodeId,
      amountMinorUnits: product.priceMinorUnits,
      memo: 'Commerce order $orderId: ${product.title}',
      ttlSeconds: 86400,
    );
    final payload = jsonEncode(<String, Object?>{
      'orderId': orderId,
      'productId': product.productId,
      'productTitle': product.title,
      'buyerNodeId': localNodeId,
      'vendorNodeId': product.vendorNodeId,
      'priceMinorUnits': product.priceMinorUnits,
      'details': details.trim(),
      'paymentBundleId': payment.bundle.bundleId,
      'createdAtMs': now.millisecondsSinceEpoch,
      'updatedAtMs': now.millisecondsSinceEpoch,
    });
    final bundle = Bundle(
      bundleId: 'commerce-order-${now.microsecondsSinceEpoch}',
      type: Bundle.typeCommerceOrder,
      sourceNodeId: localNodeId,
      destinationNodeId: product.vendorNodeId,
      destinationScope: BundleDestinationScope.direct,
      priority: BundlePriority.high,
      payload: payload,
      appId: PublishProductUseCase.commerceAppId,
      createdAt: now,
      ttlSeconds: 86400,
    );
    final signed = await _bundleSignatureService.sign(
      bundle: bundle,
      nodeId: localNodeId,
    );
    await _bundleRepository.save(signed);
    await _commerceRepository.saveLocalOrder(
      CommerceOrderDraft(
        orderId: orderId,
        productId: product.productId,
        productTitle: product.title,
        buyerNodeId: localNodeId,
        vendorNodeId: product.vendorNodeId,
        priceMinorUnits: product.priceMinorUnits,
        details: details.trim(),
        paymentBundleId: payment.bundle.bundleId,
        status: CommerceOrderStatus.pendingVendor,
        createdAt: now,
        updatedAt: now,
        sourceBundleId: signed.bundleId,
      ),
    );
    final saved = await _commerceRepository
        .watchOutgoingOrders(localNodeId: localNodeId)
        .first;
    return saved.firstWhere((order) => order.orderId == orderId);
  }
}
