import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/commerce_product.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/features/commerce/presentation/commerce_page.dart';

void main() {
  testWidgets('product detail uses image-left layout on wide screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final product = CommerceProduct(
      productId: 'product-1',
      title: 'Solar Lamp',
      description: 'Bright lamp for offline markets',
      vendorNodeId: 'vendor-1',
      priceMinorUnits: 2500,
      imageContentHash: 'sha256:image',
      imageMimeType: 'image/jpeg',
      imageExpectedChunkCount: 2,
      imageReceivedChunkCount: 1,
      availability: CommerceProductAvailability.available,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      sourceBundleId: 'bundle-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commerceProductProvider.overrideWith(
            (ref, productId) => Stream<CommerceProduct?>.value(product),
          ),
          contentStoreProvider.overrideWithValue(_EmptyContentStore()),
        ],
        child: const MaterialApp(
          home: CommerceProductDetailPage(productId: 'product-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final imageTopLeft = tester.getTopLeft(find.text('1/2 chunks'));
    final titleTopLeft = tester.getTopLeft(find.text('Solar Lamp'));

    expect(imageTopLeft.dx, lessThan(titleTopLeft.dx));
    expect(find.text('Buy for 25.00 DTN'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}

class _EmptyContentStore implements ContentStore {
  @override
  Future<void> clear() async {}

  @override
  Future<void> delete({required String contentHash}) async {}

  @override
  Future<String?> put({
    required String contentHash,
    required Uint8List bytes,
  }) async {
    return null;
  }

  @override
  Future<Uint8List?> read({required String contentHash}) async {
    return null;
  }
}
