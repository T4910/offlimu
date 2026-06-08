enum CommerceOrderStatus { pendingPayment, pendingVendor, received, rejected }

class CommerceOrder {
  const CommerceOrder({
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

  bool get isOpen =>
      status == CommerceOrderStatus.pendingPayment ||
      status == CommerceOrderStatus.pendingVendor;

  String get priceLabel => '${(priceMinorUnits / 100).toStringAsFixed(2)} DTN';
}
