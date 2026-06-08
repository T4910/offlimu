enum CommerceProductAvailability { available, outOfStock }

class CommerceProduct {
  const CommerceProduct({
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
    required this.imageReceivedChunkCount,
    required this.imageExpectedChunkCount,
    this.imageMimeType,
    this.imageLocalPath,
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
  final String? imageLocalPath;
  final int imageReceivedChunkCount;
  final int imageExpectedChunkCount;

  bool get isAvailable => availability == CommerceProductAvailability.available;
  bool get hasImage => imageLocalPath != null && imageLocalPath!.isNotEmpty;
  bool get isImageComplete =>
      hasImage ||
      (imageExpectedChunkCount > 0 &&
          imageReceivedChunkCount >= imageExpectedChunkCount);

  String get priceLabel => '${(priceMinorUnits / 100).toStringAsFixed(2)} DTN';
}
