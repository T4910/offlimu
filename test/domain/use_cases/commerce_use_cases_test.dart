import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/commerce_product.dart';
import 'package:offlimu/domain/repositories/commerce_repository.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart' as ledger;
import 'package:offlimu/domain/services/bundle_signature_service.dart';
import 'package:offlimu/domain/services/content_store.dart';
import 'package:offlimu/domain/use_cases/initiate_wallet_spend_use_case.dart';
import 'package:offlimu/domain/use_cases/prepare_bundle_content_use_case.dart';
import 'package:offlimu/domain/use_cases/publish_product_use_case.dart';
import 'package:offlimu/domain/use_cases/send_file_transfer_use_case.dart';
import 'package:offlimu/domain/use_cases/submit_commerce_order_use_case.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';
import 'package:offlimu/infrastructure/db/drift_commerce_repository.dart';
import 'package:offlimu/infrastructure/db/drift_wallet_repository.dart';

void main() {
  test(
    'publish product creates image file bundles and product broadcast',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final bundles = DriftBundleRepository(db, localNodeId: 'vendor-1');
      final commerce = DriftCommerceRepository(db);
      final contentStore = _MemoryContentStore();
      final signer = _PassThroughSignatureService();
      final sendFileTransfer = SendFileTransferUseCase(
        bundles: bundles,
        prepareBundleContent: PrepareBundleContentUseCase(
          bundles: bundles,
          contentStore: contentStore,
        ),
        bundleSignatureService: signer,
        chunkSizeBytes: 4,
      );
      final useCase = PublishProductUseCase(
        sendFileTransfer: sendFileTransfer,
        bundleRepository: bundles,
        commerceRepository: commerce,
        bundleSignatureService: signer,
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final product = await useCase.publish(
        localNodeId: 'vendor-1',
        title: 'Lamp',
        description: 'Solar lamp',
        priceMinorUnits: 2500,
        imageFileName: 'lamp.jpg',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8]),
        imageMimeType: 'image/jpeg',
      );
      final allBundles = await bundles.getAllBundles();

      expect(product.title, 'Lamp');
      expect(product.availability, CommerceProductAvailability.available);
      expect(
        allBundles.where(
          (bundle) => bundle.type == Bundle.typeFileShareMetadata,
        ),
        hasLength(1),
      );
      expect(
        allBundles.where((bundle) => bundle.type == Bundle.typeFileShareChunk),
        hasLength(2),
      );
      expect(
        allBundles.where(
          (bundle) => bundle.type == Bundle.typeCommerceProductUpsert,
        ),
        hasLength(1),
      );
    },
  );

  test('submit order creates wallet spend and direct commerce order', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final bundles = DriftBundleRepository(db, localNodeId: 'buyer-1');
    final commerce = DriftCommerceRepository(db);
    final wallet = DriftWalletRepository(db);
    final signer = _PassThroughSignatureService();
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    await wallet.appendEntry(
      ledger.WalletLedgerEntry(
        entryId: 'opening',
        kind: ledger.WalletLedgerEventKind.openingGrant,
        title: 'Opening',
        subtitle: 'Seed',
        amountMinorUnits: 5000,
        balanceImpactMinorUnits: 5000,
        status: ledger.WalletLedgerStatus.confirmed,
        createdAt: now,
      ),
    );
    await commerce.saveLocalProduct(
      CommerceProductDraft(
        productId: 'product-1',
        title: 'Rice',
        description: 'Bag of rice',
        vendorNodeId: 'vendor-1',
        priceMinorUnits: 1500,
        imageContentHash: 'sha256:image',
        imageMimeType: 'image/jpeg',
        availability: CommerceProductAvailability.available,
        createdAt: now,
        updatedAt: now,
        sourceBundleId: 'seed',
      ),
    );

    final useCase = SubmitCommerceOrderUseCase(
      commerceRepository: commerce,
      bundleRepository: bundles,
      initiateWalletSpend: InitiateWalletSpendUseCase(
        walletRepository: wallet,
        bundleRepository: bundles,
        bundleSignatureService: signer,
        now: () => now.add(const Duration(minutes: 1)),
      ),
      bundleSignatureService: signer,
      now: () => now.add(const Duration(minutes: 1)),
    );

    final order = await useCase.submit(
      localNodeId: 'buyer-1',
      productId: 'product-1',
      details: 'Deliver near the library',
    );
    final allBundles = await bundles.getAllBundles();

    expect(order.vendorNodeId, 'vendor-1');
    expect(order.paymentBundleId, isNotNull);
    expect(
      allBundles.where((bundle) => bundle.type == Bundle.typeWalletSpend),
      hasLength(1),
    );
    expect(
      allBundles.where((bundle) => bundle.type == Bundle.typeCommerceOrder),
      hasLength(1),
    );
    expect(
      allBundles
          .singleWhere((bundle) => bundle.type == Bundle.typeCommerceOrder)
          .destinationNodeId,
      'vendor-1',
    );
  });
}

class _PassThroughSignatureService implements BundleSignatureService {
  @override
  Future<Bundle> sign({required Bundle bundle, required String nodeId}) async {
    return bundle.copyWith(signature: 'signed-by-$nodeId');
  }

  @override
  Future<bool> verify(Bundle bundle) async => true;
}

class _MemoryContentStore implements ContentStore {
  final Map<String, Uint8List> _bytesByHash = <String, Uint8List>{};

  @override
  Future<void> clear() async {
    _bytesByHash.clear();
  }

  @override
  Future<String?> put({
    required String contentHash,
    required Uint8List bytes,
  }) async {
    _bytesByHash[contentHash] = bytes;
    return 'memory://$contentHash';
  }

  @override
  Future<Uint8List?> read({required String contentHash}) async {
    return _bytesByHash[contentHash];
  }
}
