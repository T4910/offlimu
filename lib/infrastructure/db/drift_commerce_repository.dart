import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/commerce_order.dart' as domain;
import 'package:offlimu/domain/entities/commerce_product.dart' as domain;
import 'package:offlimu/domain/repositories/commerce_repository.dart';
import 'package:offlimu/infrastructure/db/app_database.dart' as db;

class DriftCommerceRepository implements CommerceRepository {
  DriftCommerceRepository(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<domain.CommerceProduct>> watchAvailableProducts({
    required String localNodeId,
  }) {
    final statement = _db.select(_db.commerceProducts)
      ..where(
        (tbl) =>
            tbl.availability.equals(
              domain.CommerceProductAvailability.available.name,
            ) &
            tbl.vendorNodeId.isNotValue(localNodeId),
      )
      ..orderBy(<OrderingTerm Function(db.$CommerceProductsTable)>[
        (tbl) => OrderingTerm.desc(tbl.updatedAtMs),
        (tbl) => OrderingTerm.asc(tbl.title),
      ]);
    return statement.watch().asyncMap(_hydrateProducts);
  }

  @override
  Stream<List<domain.CommerceProduct>> watchMyListings({
    required String localNodeId,
  }) {
    final statement = _db.select(_db.commerceProducts)
      ..where((tbl) => tbl.vendorNodeId.equals(localNodeId))
      ..orderBy(<OrderingTerm Function(db.$CommerceProductsTable)>[
        (tbl) => OrderingTerm.desc(tbl.updatedAtMs),
        (tbl) => OrderingTerm.asc(tbl.title),
      ]);
    return statement.watch().asyncMap(_hydrateProducts);
  }

  @override
  Stream<List<domain.CommerceOrder>> watchIncomingOrders({
    required String localNodeId,
  }) {
    final statement = _db.select(_db.commerceOrders)
      ..where((tbl) => tbl.vendorNodeId.equals(localNodeId))
      ..orderBy(<OrderingTerm Function(db.$CommerceOrdersTable)>[
        (tbl) => OrderingTerm.desc(tbl.updatedAtMs),
      ]);
    return statement.watch().map(
      (rows) => rows.map(_toOrder).toList(growable: false),
    );
  }

  @override
  Stream<List<domain.CommerceOrder>> watchOutgoingOrders({
    required String localNodeId,
  }) {
    final statement = _db.select(_db.commerceOrders)
      ..where((tbl) => tbl.buyerNodeId.equals(localNodeId))
      ..orderBy(<OrderingTerm Function(db.$CommerceOrdersTable)>[
        (tbl) => OrderingTerm.desc(tbl.updatedAtMs),
      ]);
    return statement.watch().map(
      (rows) => rows.map(_toOrder).toList(growable: false),
    );
  }

  @override
  Future<domain.CommerceProduct?> getProduct(String productId) async {
    final row = await (_db.select(
      _db.commerceProducts,
    )..where((tbl) => tbl.productId.equals(productId))).getSingleOrNull();
    return row == null ? null : _hydrateProduct(row);
  }

  @override
  Stream<domain.CommerceProduct?> watchProduct(String productId) {
    final statement = _db.select(_db.commerceProducts)
      ..where((tbl) => tbl.productId.equals(productId));
    return statement.watchSingleOrNull().asyncMap(
      (row) => row == null ? null : _hydrateProduct(row),
    );
  }

  @override
  Future<List<domain.CommerceOrder>> getOpenIncomingOrdersForProduct({
    required String localNodeId,
    required String productId,
  }) async {
    final rows =
        await (_db.select(_db.commerceOrders)..where(
              (tbl) =>
                  tbl.vendorNodeId.equals(localNodeId) &
                  tbl.productId.equals(productId) &
                  (tbl.status.equals(
                        domain.CommerceOrderStatus.pendingPayment.name,
                      ) |
                      tbl.status.equals(
                        domain.CommerceOrderStatus.pendingVendor.name,
                      )),
            ))
            .get();
    return rows.map(_toOrder).toList(growable: false);
  }

  @override
  Future<void> saveLocalProduct(CommerceProductDraft product) {
    return _upsertProduct(product);
  }

  @override
  Future<void> saveLocalOrder(CommerceOrderDraft order) {
    return _upsertOrder(order);
  }

  @override
  Future<void> markLocalOrderStatus({
    required String orderId,
    required domain.CommerceOrderStatus status,
    required DateTime updatedAt,
    String? statusBundleId,
    String? refundBundleId,
    String? rejectionReason,
  }) async {
    await (_db.update(
      _db.commerceOrders,
    )..where((tbl) => tbl.orderId.equals(orderId))).write(
      db.CommerceOrdersCompanion(
        status: Value<String>(status.name),
        updatedAtMs: Value<int>(updatedAt.millisecondsSinceEpoch),
        lastStatusBundleId: Value<String?>(statusBundleId),
        refundBundleId: Value<String?>(refundBundleId),
        rejectionReason: Value<String?>(rejectionReason),
      ),
    );
  }

  @override
  Future<void> ingestBundle(
    Bundle bundle, {
    required String localNodeId,
  }) async {
    if (!bundle.isCommerceBundle) {
      return;
    }

    switch (bundle.type) {
      case Bundle.typeCommerceProductUpsert:
        await _ingestProductUpsert(bundle);
      case Bundle.typeCommerceProductOutOfStock:
        await _ingestOutOfStock(bundle);
      case Bundle.typeCommerceOrder:
        await _ingestOrder(bundle);
      case Bundle.typeCommerceOrderReceived:
        await _ingestOrderStatus(
          bundle,
          status: domain.CommerceOrderStatus.received,
        );
      case Bundle.typeCommerceOrderRejected:
        await _ingestOrderStatus(
          bundle,
          status: domain.CommerceOrderStatus.rejected,
        );
    }
  }

  Future<void> _ingestProductUpsert(Bundle bundle) async {
    final payload = _decode(bundle.payload);
    if (payload == null) {
      return;
    }
    final productId = _string(payload, 'productId');
    final vendorNodeId = _string(payload, 'vendorNodeId');
    final title = _string(payload, 'title');
    final description = _string(payload, 'description');
    final imageContentHash = _string(payload, 'imageContentHash');
    final priceMinorUnits = _int(payload, 'priceMinorUnits');
    final createdAtMs = _int(payload, 'createdAtMs');
    final updatedAtMs = _int(payload, 'updatedAtMs');
    if (productId == null ||
        vendorNodeId == null ||
        title == null ||
        description == null ||
        imageContentHash == null ||
        priceMinorUnits == null ||
        createdAtMs == null ||
        updatedAtMs == null ||
        vendorNodeId != bundle.sourceNodeId) {
      return;
    }

    await _upsertProduct(
      CommerceProductDraft(
        productId: productId,
        title: title,
        description: description,
        vendorNodeId: vendorNodeId,
        priceMinorUnits: priceMinorUnits,
        imageContentHash: imageContentHash,
        imageMimeType: _string(payload, 'imageMimeType'),
        availability: domain.CommerceProductAvailability.available,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
        sourceBundleId: bundle.bundleId,
      ),
    );
  }

  Future<void> _ingestOutOfStock(Bundle bundle) async {
    final payload = _decode(bundle.payload);
    if (payload == null) {
      return;
    }
    final productId = _string(payload, 'productId');
    final vendorNodeId = _string(payload, 'vendorNodeId');
    final updatedAtMs = _int(payload, 'updatedAtMs');
    if (productId == null ||
        vendorNodeId == null ||
        updatedAtMs == null ||
        vendorNodeId != bundle.sourceNodeId) {
      return;
    }

    final existing = await (_db.select(
      _db.commerceProducts,
    )..where((tbl) => tbl.productId.equals(productId))).getSingleOrNull();
    if (existing == null ||
        existing.vendorNodeId != vendorNodeId ||
        updatedAtMs < existing.updatedAtMs) {
      return;
    }

    await (_db.update(
      _db.commerceProducts,
    )..where((tbl) => tbl.productId.equals(productId))).write(
      db.CommerceProductsCompanion(
        availability: Value<String>(
          domain.CommerceProductAvailability.outOfStock.name,
        ),
        updatedAtMs: Value<int>(updatedAtMs),
        sourceBundleId: Value<String>(bundle.bundleId),
      ),
    );
  }

  Future<void> _ingestOrder(Bundle bundle) async {
    final payload = _decode(bundle.payload);
    if (payload == null) {
      return;
    }
    final orderId = _string(payload, 'orderId');
    final productId = _string(payload, 'productId');
    final buyerNodeId = _string(payload, 'buyerNodeId');
    final vendorNodeId = _string(payload, 'vendorNodeId');
    final priceMinorUnits = _int(payload, 'priceMinorUnits');
    final createdAtMs = _int(payload, 'createdAtMs');
    final updatedAtMs = _int(payload, 'updatedAtMs') ?? createdAtMs;
    if (orderId == null ||
        productId == null ||
        buyerNodeId == null ||
        vendorNodeId == null ||
        priceMinorUnits == null ||
        createdAtMs == null ||
        updatedAtMs == null ||
        buyerNodeId != bundle.sourceNodeId ||
        vendorNodeId != bundle.destinationNodeId) {
      return;
    }

    await _upsertOrder(
      CommerceOrderDraft(
        orderId: orderId,
        productId: productId,
        productTitle: _string(payload, 'productTitle'),
        buyerNodeId: buyerNodeId,
        vendorNodeId: vendorNodeId,
        priceMinorUnits: priceMinorUnits,
        details: _string(payload, 'details') ?? '',
        paymentBundleId: _string(payload, 'paymentBundleId'),
        status: domain.CommerceOrderStatus.pendingVendor,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
        sourceBundleId: bundle.bundleId,
      ),
    );
  }

  Future<void> _ingestOrderStatus(
    Bundle bundle, {
    required domain.CommerceOrderStatus status,
  }) async {
    final payload = _decode(bundle.payload);
    if (payload == null) {
      return;
    }
    final orderId = _string(payload, 'orderId');
    final vendorNodeId = _string(payload, 'vendorNodeId');
    final updatedAtMs = _int(payload, 'updatedAtMs');
    if (orderId == null ||
        vendorNodeId == null ||
        updatedAtMs == null ||
        vendorNodeId != bundle.sourceNodeId) {
      return;
    }

    final existing = await (_db.select(
      _db.commerceOrders,
    )..where((tbl) => tbl.orderId.equals(orderId))).getSingleOrNull();
    if (existing == null ||
        existing.vendorNodeId != vendorNodeId ||
        updatedAtMs < existing.updatedAtMs) {
      return;
    }

    await (_db.update(
      _db.commerceOrders,
    )..where((tbl) => tbl.orderId.equals(orderId))).write(
      db.CommerceOrdersCompanion(
        status: Value<String>(status.name),
        updatedAtMs: Value<int>(updatedAtMs),
        lastStatusBundleId: Value<String>(bundle.bundleId),
        refundBundleId: Value<String?>(_string(payload, 'refundBundleId')),
        rejectionReason: Value<String?>(_string(payload, 'reason')),
      ),
    );
  }

  Future<void> _upsertProduct(CommerceProductDraft product) async {
    final existing =
        await (_db.select(_db.commerceProducts)
              ..where((tbl) => tbl.productId.equals(product.productId)))
            .getSingleOrNull();
    if (existing != null &&
        (existing.vendorNodeId != product.vendorNodeId ||
            product.updatedAt.millisecondsSinceEpoch < existing.updatedAtMs)) {
      return;
    }

    await _db
        .into(_db.commerceProducts)
        .insertOnConflictUpdate(
          db.CommerceProductsCompanion(
            productId: Value<String>(product.productId),
            title: Value<String>(product.title),
            description: Value<String>(product.description),
            vendorNodeId: Value<String>(product.vendorNodeId),
            priceMinorUnits: Value<int>(product.priceMinorUnits),
            imageContentHash: Value<String>(product.imageContentHash),
            imageMimeType: Value<String?>(product.imageMimeType),
            availability: Value<String>(product.availability.name),
            createdAtMs: Value<int>(product.createdAt.millisecondsSinceEpoch),
            updatedAtMs: Value<int>(product.updatedAt.millisecondsSinceEpoch),
            sourceBundleId: Value<String>(product.sourceBundleId),
          ),
        );
  }

  Future<void> _upsertOrder(CommerceOrderDraft order) async {
    final existing = await (_db.select(
      _db.commerceOrders,
    )..where((tbl) => tbl.orderId.equals(order.orderId))).getSingleOrNull();
    if (existing != null &&
        order.updatedAt.millisecondsSinceEpoch < existing.updatedAtMs) {
      return;
    }

    await _db
        .into(_db.commerceOrders)
        .insertOnConflictUpdate(
          db.CommerceOrdersCompanion(
            orderId: Value<String>(order.orderId),
            productId: Value<String>(order.productId),
            productTitle: Value<String?>(order.productTitle),
            buyerNodeId: Value<String>(order.buyerNodeId),
            vendorNodeId: Value<String>(order.vendorNodeId),
            priceMinorUnits: Value<int>(order.priceMinorUnits),
            details: Value<String>(order.details),
            paymentBundleId: Value<String?>(order.paymentBundleId),
            refundBundleId: Value<String?>(order.refundBundleId),
            status: Value<String>(order.status.name),
            createdAtMs: Value<int>(order.createdAt.millisecondsSinceEpoch),
            updatedAtMs: Value<int>(order.updatedAt.millisecondsSinceEpoch),
            sourceBundleId: Value<String>(order.sourceBundleId),
            lastStatusBundleId: Value<String?>(order.lastStatusBundleId),
            rejectionReason: Value<String?>(order.rejectionReason),
          ),
        );
  }

  Future<List<domain.CommerceProduct>> _hydrateProducts(
    List<db.CommerceProduct> rows,
  ) async {
    final products = <domain.CommerceProduct>[];
    for (final row in rows) {
      products.add(await _hydrateProduct(row));
    }
    return products;
  }

  Future<domain.CommerceProduct> _hydrateProduct(db.CommerceProduct row) async {
    final metadata =
        await (_db.select(_db.contentMetadata)
              ..where((tbl) => tbl.contentHash.equals(row.imageContentHash)))
            .getSingleOrNull();
    final chunkCountExpression = _db.bundleRecords.bundleId.count();
    final chunkQuery = _db.selectOnly(_db.bundleRecords)
      ..addColumns([chunkCountExpression])
      ..where(
        _db.bundleRecords.payloadRef.equals(row.imageContentHash) &
            _db.bundleRecords.type.equals(Bundle.typeFileShareChunk),
      );
    final receivedChunks = await chunkQuery
        .map((result) => result.read(chunkCountExpression) ?? 0)
        .getSingle();
    final expectedChunks = metadata?.chunkCount ?? receivedChunks;

    return domain.CommerceProduct(
      productId: row.productId,
      title: row.title,
      description: row.description,
      vendorNodeId: row.vendorNodeId,
      priceMinorUnits: row.priceMinorUnits,
      imageContentHash: row.imageContentHash,
      imageMimeType: metadata?.mimeType ?? row.imageMimeType,
      availability: _productAvailability(row.availability),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAtMs),
      sourceBundleId: row.sourceBundleId,
      imageLocalPath: metadata?.localPath,
      imageReceivedChunkCount: metadata?.localPath == null
          ? receivedChunks
          : (metadata?.chunkCount ?? receivedChunks),
      imageExpectedChunkCount: expectedChunks,
    );
  }

  domain.CommerceOrder _toOrder(db.CommerceOrder row) {
    return domain.CommerceOrder(
      orderId: row.orderId,
      productId: row.productId,
      productTitle: row.productTitle,
      buyerNodeId: row.buyerNodeId,
      vendorNodeId: row.vendorNodeId,
      priceMinorUnits: row.priceMinorUnits,
      details: row.details,
      paymentBundleId: row.paymentBundleId,
      refundBundleId: row.refundBundleId,
      status: _orderStatus(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAtMs),
      sourceBundleId: row.sourceBundleId,
      lastStatusBundleId: row.lastStatusBundleId,
      rejectionReason: row.rejectionReason,
    );
  }

  domain.CommerceProductAvailability _productAvailability(String value) {
    return domain.CommerceProductAvailability.values.firstWhere(
      (status) => status.name == value,
      orElse: () => domain.CommerceProductAvailability.available,
    );
  }

  domain.CommerceOrderStatus _orderStatus(String value) {
    return domain.CommerceOrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => domain.CommerceOrderStatus.pendingVendor,
    );
  }

  Map<String, Object?>? _decode(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }
    try {
      final parsed = jsonDecode(payload);
      if (parsed is! Map) {
        return null;
      }
      return parsed.cast<String, Object?>();
    } catch (_) {
      return null;
    }
  }

  String? _string(Map<String, Object?> payload, String key) {
    final value = payload[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  int? _int(Map<String, Object?> payload, String key) {
    final value = payload[key];
    return value is num ? value.toInt() : null;
  }
}
