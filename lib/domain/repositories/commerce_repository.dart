import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/commerce_order.dart';
import 'package:offlimu/domain/entities/commerce_product.dart';

abstract interface class CommerceRepository {
  Stream<List<CommerceProduct>> watchAvailableProducts({
    required String localNodeId,
  });

  Stream<List<CommerceProduct>> watchMyListings({required String localNodeId});

  Stream<List<CommerceOrder>> watchIncomingOrders({
    required String localNodeId,
  });

  Stream<List<CommerceOrder>> watchOutgoingOrders({
    required String localNodeId,
  });

  Future<CommerceProduct?> getProduct(String productId);

  Stream<CommerceProduct?> watchProduct(String productId);

  Future<List<CommerceOrder>> getOpenIncomingOrdersForProduct({
    required String localNodeId,
    required String productId,
  });

  Future<void> saveLocalProduct(CommerceProductDraft product);

  Future<void> saveLocalOrder(CommerceOrderDraft order);

  Future<void> markLocalOrderStatus({
    required String orderId,
    required CommerceOrderStatus status,
    required DateTime updatedAt,
    String? statusBundleId,
    String? refundBundleId,
    String? rejectionReason,
  });

  Future<void> ingestBundle(Bundle bundle, {required String localNodeId});
}

class CommerceProductDraft {
  const CommerceProductDraft({
    required this.productId,
    required this.title,
    required this.description,
    required this.vendorNodeId,
    required this.priceMinorUnits,
    required this.imageContentHash,
    required this.availability,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceBundleId,
    this.imageMimeType,
  });

  final String productId;
  final String title;
  final String description;
  final String vendorNodeId;
  final int priceMinorUnits;
  final String imageContentHash;
  final String? imageMimeType;
  final CommerceProductAvailability availability;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sourceBundleId;
}

class CommerceOrderDraft {
  const CommerceOrderDraft({
    required this.orderId,
    required this.productId,
    required this.buyerNodeId,
    required this.vendorNodeId,
    required this.priceMinorUnits,
    required this.details,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceBundleId,
    this.productTitle,
    this.paymentBundleId,
    this.refundBundleId,
    this.lastStatusBundleId,
    this.rejectionReason,
  });

  final String orderId;
  final String productId;
  final String? productTitle;
  final String buyerNodeId;
  final String vendorNodeId;
  final int priceMinorUnits;
  final String details;
  final String? paymentBundleId;
  final String? refundBundleId;
  final CommerceOrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sourceBundleId;
  final String? lastStatusBundleId;
  final String? rejectionReason;
}
