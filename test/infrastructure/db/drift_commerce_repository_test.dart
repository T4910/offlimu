import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/commerce_order.dart';
import 'package:offlimu/domain/entities/commerce_product.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_commerce_repository.dart';

void main() {
  test('ingests product upserts, ignores stale and forged updates', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftCommerceRepository(db);
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    await repository.ingestBundle(
      _productBundle(
        productId: 'product-1',
        vendorNodeId: 'vendor-1',
        title: 'Solar lamp',
        updatedAt: now,
      ),
      localNodeId: 'buyer-1',
    );

    await repository.ingestBundle(
      _productBundle(
        productId: 'product-1',
        vendorNodeId: 'vendor-1',
        title: 'Old title',
        updatedAt: now.subtract(const Duration(minutes: 1)),
      ),
      localNodeId: 'buyer-1',
    );

    await repository.ingestBundle(
      _productBundle(
        productId: 'product-1',
        vendorNodeId: 'vendor-1',
        sourceNodeId: 'attacker',
        title: 'Forged title',
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
      localNodeId: 'buyer-1',
    );

    final product = await repository.getProduct('product-1');
    expect(product?.title, 'Solar lamp');
    expect(product?.availability, CommerceProductAvailability.available);
  });

  test('out-of-stock and order status bundles update projections', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftCommerceRepository(db);
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    await repository.ingestBundle(
      _productBundle(
        productId: 'product-1',
        vendorNodeId: 'vendor-1',
        title: 'Rice bag',
        updatedAt: now,
      ),
      localNodeId: 'buyer-1',
    );
    await repository.ingestBundle(
      _orderBundle(now: now.add(const Duration(minutes: 1))),
      localNodeId: 'vendor-1',
    );
    await repository.ingestBundle(
      _outOfStockBundle(
        productId: 'product-1',
        vendorNodeId: 'vendor-1',
        updatedAt: now.add(const Duration(minutes: 2)),
      ),
      localNodeId: 'buyer-1',
    );
    await repository.ingestBundle(
      _receivedBundle(now: now.add(const Duration(minutes: 3))),
      localNodeId: 'buyer-1',
    );

    final product = await repository.getProduct('product-1');
    final incoming = await repository
        .watchIncomingOrders(localNodeId: 'vendor-1')
        .first;

    expect(product?.availability, CommerceProductAvailability.outOfStock);
    expect(incoming.single.status, CommerceOrderStatus.received);
  });
}

Bundle _productBundle({
  required String productId,
  required String vendorNodeId,
  required String title,
  required DateTime updatedAt,
  String? sourceNodeId,
}) {
  return Bundle(
    bundleId: 'bundle-$title-${updatedAt.microsecondsSinceEpoch}',
    type: Bundle.typeCommerceProductUpsert,
    sourceNodeId: sourceNodeId ?? vendorNodeId,
    destinationScope: BundleDestinationScope.broadcast,
    payload: jsonEncode(<String, Object?>{
      'productId': productId,
      'title': title,
      'description': 'Useful product',
      'vendorNodeId': vendorNodeId,
      'priceMinorUnits': 1200,
      'imageContentHash': 'sha256:image',
      'imageMimeType': 'image/jpeg',
      'createdAtMs': updatedAt.millisecondsSinceEpoch,
      'updatedAtMs': updatedAt.millisecondsSinceEpoch,
    }),
    appId: 'offlimu.commerce',
    createdAt: updatedAt,
    ttlSeconds: 86400,
  );
}

Bundle _outOfStockBundle({
  required String productId,
  required String vendorNodeId,
  required DateTime updatedAt,
}) {
  return Bundle(
    bundleId: 'out-${updatedAt.microsecondsSinceEpoch}',
    type: Bundle.typeCommerceProductOutOfStock,
    sourceNodeId: vendorNodeId,
    destinationScope: BundleDestinationScope.broadcast,
    payload: jsonEncode(<String, Object?>{
      'productId': productId,
      'vendorNodeId': vendorNodeId,
      'updatedAtMs': updatedAt.millisecondsSinceEpoch,
    }),
    appId: 'offlimu.commerce',
    createdAt: updatedAt,
    ttlSeconds: 86400,
  );
}

Bundle _orderBundle({required DateTime now}) {
  return Bundle(
    bundleId: 'order-bundle',
    type: Bundle.typeCommerceOrder,
    sourceNodeId: 'buyer-1',
    destinationNodeId: 'vendor-1',
    payload: jsonEncode(<String, Object?>{
      'orderId': 'order-1',
      'productId': 'product-1',
      'productTitle': 'Rice bag',
      'buyerNodeId': 'buyer-1',
      'vendorNodeId': 'vendor-1',
      'priceMinorUnits': 1200,
      'details': 'Deliver by the school gate',
      'paymentBundleId': 'wallet-spend-1',
      'createdAtMs': now.millisecondsSinceEpoch,
      'updatedAtMs': now.millisecondsSinceEpoch,
    }),
    appId: 'offlimu.commerce',
    createdAt: now,
    ttlSeconds: 86400,
  );
}

Bundle _receivedBundle({required DateTime now}) {
  return Bundle(
    bundleId: 'received-bundle',
    type: Bundle.typeCommerceOrderReceived,
    sourceNodeId: 'vendor-1',
    destinationNodeId: 'buyer-1',
    payload: jsonEncode(<String, Object?>{
      'orderId': 'order-1',
      'vendorNodeId': 'vendor-1',
      'buyerNodeId': 'buyer-1',
      'updatedAtMs': now.millisecondsSinceEpoch,
    }),
    appId: 'offlimu.commerce',
    createdAt: now,
    ttlSeconds: 86400,
  );
}
