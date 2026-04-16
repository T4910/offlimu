import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/node_runtime/queue_pruning.dart';

void main() {
  Bundle buildBundle({
    required String id,
    required DateTime createdAt,
    BundlePriority priority = BundlePriority.normal,
    String type = Bundle.typeChatMessage,
  }) {
    return Bundle(
      bundleId: id,
      type: type,
      sourceNodeId: 'node-a',
      createdAt: createdAt,
      ttlSeconds: 3600,
      priority: priority,
    );
  }

  test('returns empty when queue is within limit', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final bundles = <Bundle>[
      buildBundle(id: 'b1', createdAt: now),
      buildBundle(id: 'b2', createdAt: now.add(const Duration(seconds: 1))),
    ];

    final pruned = selectPendingBundlesForPruning(
      bundles,
      maxPendingBundles: 2,
    );

    expect(pruned, isEmpty);
  });

  test('prunes oldest low-priority bundles first', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final bundles = <Bundle>[
      buildBundle(id: 'low-old', createdAt: now, priority: BundlePriority.low),
      buildBundle(
        id: 'normal-old',
        createdAt: now.add(const Duration(seconds: 1)),
        priority: BundlePriority.normal,
      ),
      buildBundle(
        id: 'high-new',
        createdAt: now.add(const Duration(seconds: 2)),
        priority: BundlePriority.high,
      ),
    ];

    final pruned = selectPendingBundlesForPruning(
      bundles,
      maxPendingBundles: 2,
    );

    expect(pruned, hasLength(1));
    expect(pruned.single.bundleId, 'low-old');
  });

  test('preserves ack and critical bundles until necessary', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final bundles = <Bundle>[
      buildBundle(
        id: 'ack-old',
        createdAt: now,
        type: Bundle.typeAck,
        priority: BundlePriority.low,
      ),
      buildBundle(
        id: 'critical-old',
        createdAt: now.add(const Duration(seconds: 1)),
        priority: BundlePriority.critical,
      ),
      buildBundle(
        id: 'normal-mid',
        createdAt: now.add(const Duration(seconds: 2)),
        priority: BundlePriority.normal,
      ),
      buildBundle(
        id: 'low-new',
        createdAt: now.add(const Duration(seconds: 3)),
        priority: BundlePriority.low,
      ),
    ];

    final pruned = selectPendingBundlesForPruning(
      bundles,
      maxPendingBundles: 2,
    );

    expect(pruned, hasLength(2));
    expect(
      pruned.map((b) => b.bundleId),
      containsAll(<String>['low-new', 'normal-mid']),
    );
    expect(pruned.map((b) => b.bundleId), isNot(contains('ack-old')));
    expect(pruned.map((b) => b.bundleId), isNot(contains('critical-old')));
  });
}
