import 'package:offlimu/domain/entities/bundle.dart';

List<Bundle> selectPendingBundlesForPruning(
  List<Bundle> pendingBundles, {
  required int maxPendingBundles,
}) {
  if (maxPendingBundles < 0) {
    throw ArgumentError.value(
      maxPendingBundles,
      'maxPendingBundles',
      'Must be non-negative.',
    );
  }

  if (pendingBundles.length <= maxPendingBundles) {
    return const <Bundle>[];
  }

  final int overflow = pendingBundles.length - maxPendingBundles;
  final List<Bundle> candidates = pendingBundles.toList(growable: false)
    ..sort(_comparePrunePriority);

  return candidates.take(overflow).toList(growable: false);
}

int _comparePrunePriority(Bundle a, Bundle b) {
  final int protectedCompare = _protectedRank(a).compareTo(_protectedRank(b));
  if (protectedCompare != 0) {
    return protectedCompare;
  }

  final int priorityCompare = _bundlePriorityRank(
    a.priority,
  ).compareTo(_bundlePriorityRank(b.priority));
  if (priorityCompare != 0) {
    return priorityCompare;
  }

  return a.createdAt.compareTo(b.createdAt);
}

int _protectedRank(Bundle bundle) {
  if (bundle.isAck || bundle.priority == BundlePriority.critical) {
    return 1;
  }
  return 0;
}

int _bundlePriorityRank(BundlePriority priority) {
  return switch (priority) {
    BundlePriority.low => 0,
    BundlePriority.normal => 1,
    BundlePriority.high => 2,
    BundlePriority.critical => 3,
  };
}
