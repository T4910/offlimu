import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/sync_contract.dart';

abstract interface class SyncApi {
  bool get mockMode;

  // Upload response contains explicit confirmations and rejections for sent bundles.
  Future<SyncUploadResult> uploadBundles(List<Bundle> bundles);

  // Fetch response contains new inbound bundles to persist/process locally.
  Future<SyncFetchResult> fetchRemoteBundles({required DateTime since});
}
