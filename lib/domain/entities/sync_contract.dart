import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/web_search_result.dart';

class SyncRejection {
  const SyncRejection({required this.bundleId, required this.reason});

  final String bundleId;
  final String reason;
}

class SyncUploadResult {
  const SyncUploadResult({
    this.rejections = const <SyncRejection>[],
    this.webSearchResults = const <WebSearchResult>[],
  });

  final List<SyncRejection> rejections;
  final List<WebSearchResult> webSearchResults;
}

class SyncFetchResult {
  const SyncFetchResult({required this.bundles});

  final List<Bundle> bundles;
}
