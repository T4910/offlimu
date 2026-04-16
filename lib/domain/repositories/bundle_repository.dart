import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:offlimu/domain/entities/content_metadata_record.dart';

abstract interface class BundleRepository {
  Future<void> save(Bundle bundle);
  Future<Bundle?> getById(String bundleId);
  Future<void> saveContentMetadata(ContentMetadataRecord metadata);
  Future<ContentMetadataRecord?> getContentMetadata(String contentHash);
  Stream<List<ContentMetadataRecord>> watchRecentContentMetadata({
    int limit = 50,
  });
  Future<void> markSent(String bundleId);
  Future<void> markSendFailed(String bundleId, {required String errorMessage});
  Future<void> markRejected(String bundleId, {required String reason});
  Future<void> markAcknowledged(String bundleId);
  Future<bool> recordAckReceipt(Bundle ackBundle);
  Future<List<Bundle>> getPendingBundles();
  Stream<List<Bundle>> watchPendingBundles();
  Stream<List<Bundle>> watchBundlesByType(String type);
  Stream<List<AckAuditEvent>> watchRecentAckEvents({int limit = 20});
}
