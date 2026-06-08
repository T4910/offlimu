import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class BundleRecords extends Table {
  TextColumn get bundleId => text()();
  TextColumn get type => text()();
  TextColumn get sourceNodeId => text()();
  TextColumn get sourcePublicKey => text().nullable()();
  TextColumn get destinationNodeId => text().nullable()();
  TextColumn get destinationScope =>
      text().withDefault(const Constant('direct'))();
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  TextColumn get ackForBundleId => text().nullable()();
  TextColumn get payload => text().nullable()();
  TextColumn get payloadRef => text().nullable()();
  TextColumn get signature => text().nullable()();
  TextColumn get appId => text().withDefault(const Constant('offlimu.chat'))();
  IntColumn get createdAtMs => integer()();
  IntColumn get expiresAtMs => integer().nullable()();
  IntColumn get ttlSeconds => integer()();
  IntColumn get hopCount => integer().withDefault(const Constant(0))();
  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();
  IntColumn get sentAtMs => integer().nullable()();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {bundleId};
}

class PeerContacts extends Table {
  TextColumn get nodeId => text()();
  TextColumn get host => text()();
  IntColumn get port => integer()();
  IntColumn get lastSeenMs => integer()();
  IntColumn get seenCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>>? get primaryKey => {nodeId};
}

class SyncJobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get startedAtMs => integer()();
  IntColumn get completedAtMs => integer()();
  IntColumn get uploadedCount => integer().withDefault(const Constant(0))();
  IntColumn get downloadedCount => integer().withDefault(const Constant(0))();
  BoolColumn get success => boolean()();
  BoolColumn get mockMode => boolean()();
  BoolColumn get gatewayEnabled => boolean()();
  BoolColumn get internetReachable => boolean()();
  TextColumn get errorMessage => text().nullable()();
}

class MessageProjections extends Table {
  TextColumn get bundleId => text()();
  TextColumn get sourceNodeId => text()();
  TextColumn get destinationNodeId => text().nullable()();
  TextColumn get body => text()();
  IntColumn get createdAtMs => integer()();
  BoolColumn get isOutgoing => boolean()();
  TextColumn get deliveryStatus => text()();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {bundleId};
}

class AckEvents extends Table {
  TextColumn get ackBundleId => text()();
  TextColumn get ackForBundleId => text().nullable()();
  TextColumn get sourceNodeId => text()();
  IntColumn get firstReceivedAtMs => integer()();
  IntColumn get lastReceivedAtMs => integer()();
  IntColumn get duplicateCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>>? get primaryKey => {ackBundleId};
}

class ContentMetadata extends Table {
  @override
  String get tableName => 'content_metadata';

  TextColumn get contentHash => text()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get totalBytes => integer()();
  IntColumn get chunkCount => integer().withDefault(const Constant(1))();
  IntColumn get createdAtMs => integer()();
  TextColumn get localPath => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {contentHash};
}

class WalletLedgerEntries extends Table {
  TextColumn get entryId => text()();
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text()();
  IntColumn get amountMinorUnits => integer()();
  IntColumn get balanceImpactMinorUnits => integer()();
  TextColumn get status => text()();
  IntColumn get createdAtMs => integer()();
  TextColumn get memo => text().nullable()();
  TextColumn get counterpartyNodeId => text().nullable()();
  TextColumn get sourceBundleId => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {entryId};
}

class WebIndexRecords extends Table {
  @override
  String get tableName => 'web_index_entries';

  TextColumn get contentHash => text()();
  TextColumn get title => text()();
  TextColumn get url => text()();
  TextColumn get snippet => text()();
  TextColumn get query => text()();
  TextColumn get sourceRequestId => text()();
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();
  IntColumn get expectedChunkCount =>
      integer().withDefault(const Constant(1))();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>>? get primaryKey => {contentHash};
}

class CommerceProducts extends Table {
  @override
  String get tableName => 'commerce_products';

  TextColumn get productId => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get vendorNodeId => text()();
  IntColumn get priceMinorUnits => integer()();
  TextColumn get imageContentHash => text()();
  TextColumn get imageMimeType => text().nullable()();
  TextColumn get availability => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  TextColumn get sourceBundleId => text()();

  @override
  Set<Column<Object>>? get primaryKey => {productId};
}

class CommerceOrders extends Table {
  @override
  String get tableName => 'commerce_orders';

  TextColumn get orderId => text()();
  TextColumn get productId => text()();
  TextColumn get productTitle => text().nullable()();
  TextColumn get buyerNodeId => text()();
  TextColumn get vendorNodeId => text()();
  IntColumn get priceMinorUnits => integer()();
  TextColumn get details => text()();
  TextColumn get paymentBundleId => text().nullable()();
  TextColumn get refundBundleId => text().nullable()();
  TextColumn get status => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  TextColumn get sourceBundleId => text()();
  TextColumn get lastStatusBundleId => text().nullable()();
  TextColumn get rejectionReason => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {orderId};
}

@DriftDatabase(
  tables: <Type>[
    BundleRecords,
    PeerContacts,
    SyncJobs,
    MessageProjections,
    AckEvents,
    ContentMetadata,
    WalletLedgerEntries,
    WebIndexRecords,
    CommerceProducts,
    CommerceOrders,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Migration policy:
      // 1) Never rewrite/drop user content in onUpgrade.
      // 2) Prefer additive migrations (new columns/tables) with defaults.
      // 3) Keep every historical step explicit and idempotent by version gate.
      if (from < 2) {
        await m.addColumn(bundleRecords, bundleRecords.destinationNodeId);
        await m.addColumn(bundleRecords, bundleRecords.ackForBundleId);
      }
      if (from < 3) {
        await m.addColumn(bundleRecords, bundleRecords.payload);
      }
      if (from < 4) {
        await m.addColumn(bundleRecords, bundleRecords.sentAtMs);
        await m.addColumn(bundleRecords, bundleRecords.failedAttempts);
        await m.addColumn(bundleRecords, bundleRecords.lastError);
      }
      if (from < 5) {
        await m.createTable(peerContacts);
      }
      if (from < 6) {
        await m.createTable(syncJobs);
      }
      if (from < 7) {
        await m.createTable(messageProjections);
      }
      if (from < 8) {
        await m.addColumn(bundleRecords, bundleRecords.hopCount);
      }
      if (from < 9) {
        await m.createTable(ackEvents);
      }
      if (from < 10) {
        await m.addColumn(bundleRecords, bundleRecords.destinationScope);
        await m.addColumn(bundleRecords, bundleRecords.priority);
        await m.addColumn(bundleRecords, bundleRecords.payloadRef);
        await m.addColumn(bundleRecords, bundleRecords.signature);
        await m.addColumn(bundleRecords, bundleRecords.appId);
        await m.addColumn(bundleRecords, bundleRecords.expiresAtMs);
      }
      if (from < 11) {
        await m.createTable(contentMetadata);
      }
      if (from < 12) {
        await m.addColumn(bundleRecords, bundleRecords.sourcePublicKey);
      }
      if (from < 13) {
        await m.createTable(walletLedgerEntries);
      }
      if (from < 14) {
        await m.createTable(webIndexRecords);
      }
      if (from < 15) {
        await m.createTable(commerceProducts);
        await m.createTable(commerceOrders);
      }
    },
  );

  Future<bool> runHealthCheck() async {
    try {
      final result = await customSelect('PRAGMA quick_check;').getSingle();
      final String? value = result.data.values.firstOrNull?.toString();
      return value == 'ok';
    } catch (_) {
      return false;
    }
  }

  Future<void> runVacuum() async {
    await customStatement('VACUUM;');
  }

  Future<void> clearAllUserData() async {
    await transaction(() async {
      await delete(messageProjections).go();
      await delete(ackEvents).go();
      await delete(bundleRecords).go();
      await delete(peerContacts).go();
      await delete(syncJobs).go();
      await delete(contentMetadata).go();
      await delete(walletLedgerEntries).go();
      await delete(webIndexRecords).go();
      await delete(commerceProducts).go();
      await delete(commerceOrders).go();
      await customStatement('DELETE FROM sqlite_sequence;');
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File(p.join(directory.path, 'offlimu.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
