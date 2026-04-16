import 'package:offlimu/domain/entities/bundle.dart';

class SyncRejection {
  const SyncRejection({required this.bundleId, required this.reason});

  final String bundleId;
  final String reason;
}

class SyncUploadResult {
  const SyncUploadResult({
    required this.acknowledgedBundleIds,
    required this.rejections,
  });

  final List<String> acknowledgedBundleIds;
  final List<SyncRejection> rejections;
}

class SyncFetchResult {
  const SyncFetchResult({required this.bundles});

  final List<Bundle> bundles;
}
