import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/infrastructure/db/app_database.dart';
import 'package:offlimu/infrastructure/db/drift_bundle_repository.dart';

void main() {
  group('DriftBundleRepository ACK state machine', () {
    test(
      'recordAckReceipt is idempotent and increments duplicate count',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        final repository = DriftBundleRepository(db, localNodeId: 'node-a');
        final ackBundle = Bundle(
          bundleId: 'ack-1',
          type: Bundle.typeAck,
          sourceNodeId: 'node-b',
          destinationNodeId: 'node-a',
          ackForBundleId: 'msg-1',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
          ttlSeconds: 300,
        );

        final first = await repository.recordAckReceipt(ackBundle);
        final second = await repository.recordAckReceipt(ackBundle);

        expect(first, isTrue);
        expect(second, isFalse);

        final events = await repository.watchRecentAckEvents(limit: 5).first;
        expect(events, hasLength(1));
        expect(events.single.ackBundleId, 'ack-1');
        expect(events.single.ackForBundleId, 'msg-1');
        expect(events.single.duplicateCount, 1);
        expect(events.single.totalReceipts, 2);
      },
    );

    test('markAcknowledged updates bundle acknowledged flag', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final repository = DriftBundleRepository(db, localNodeId: 'node-a');
      final pending = Bundle(
        bundleId: 'msg-2',
        type: Bundle.typeChatMessage,
        sourceNodeId: 'node-a',
        destinationNodeId: 'node-b',
        payload: 'hello',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
        ttlSeconds: 3600,
      );

      await repository.save(pending);
      await repository.markAcknowledged('msg-2');

      final updated = await repository.getById('msg-2');
      expect(updated, isNotNull);
      expect(updated!.acknowledged, isTrue);
    });
  });
}
