import 'package:dio/dio.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/sync_contract.dart';
import 'package:offlimu/domain/services/sync_api.dart';

class DioSyncApi implements SyncApi {
  DioSyncApi({required String baseUrl, this.mockMode = true})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  final Dio _dio;

  @override
  final bool mockMode;

  final List<Bundle> _mockRemoteInbox = <Bundle>[];

  @override
  Future<SyncUploadResult> uploadBundles(List<Bundle> bundles) async {
    if (bundles.isEmpty) {
      return const SyncUploadResult(
        acknowledgedBundleIds: <String>[],
        rejections: <SyncRejection>[],
      );
    }

    if (mockMode) {
      final List<String> acknowledged = <String>[];
      final List<SyncRejection> rejected = <SyncRejection>[];

      for (final bundle in bundles) {
        final bool reject = (bundle.payload ?? '').contains('[reject]');
        if (reject) {
          final rejection = _buildRejectionFor(bundle);
          _mockRemoteInbox.add(rejection);
          rejected.add(
            SyncRejection(
              bundleId: bundle.bundleId,
              reason: rejection.payload ?? 'Rejected by server policy (mock)',
            ),
          );
        } else {
          final confirmation = _buildConfirmationFor(bundle);
          _mockRemoteInbox.add(confirmation);
          acknowledged.add(bundle.bundleId);
        }
      }

      return SyncUploadResult(
        acknowledgedBundleIds: acknowledged,
        rejections: rejected,
      );
    }

    final response = await _dio.post(
      '/sync/upload',
      data: <String, Object?>{
        'bundles': bundles.map(_bundleToJson).toList(growable: false),
      },
    );

    final data = _asMap(response.data);
    final acknowledged = _asStringList(data['acknowledgedBundleIds']);
    final rejectedRaw = data['rejections'];
    final rejected = rejectedRaw is List
        ? rejectedRaw
              .whereType<Map>()
              .map((raw) {
                final map = Map<String, dynamic>.from(raw);
                return SyncRejection(
                  bundleId: map['bundleId'] as String,
                  reason: (map['reason'] as String?) ?? 'Rejected by server',
                );
              })
              .toList(growable: false)
        : const <SyncRejection>[];

    return SyncUploadResult(
      acknowledgedBundleIds: acknowledged,
      rejections: rejected,
    );
  }

  @override
  Future<SyncFetchResult> fetchRemoteBundles({required DateTime since}) async {
    if (mockMode) {
      final List<Bundle> result = _mockRemoteInbox
          .where((bundle) => bundle.createdAt.isAfter(since))
          .toList(growable: false);
      _mockRemoteInbox.removeWhere((bundle) => result.contains(bundle));
      return SyncFetchResult(bundles: result);
    }

    final response = await _dio.get(
      '/sync/fetch',
      queryParameters: <String, Object?>{
        'sinceMs': since.millisecondsSinceEpoch,
      },
    );

    final Map<String, dynamic> data = _asMap(response.data);
    final Object? bundlesRaw = data['bundles'];
    if (bundlesRaw is! List) {
      return const SyncFetchResult(bundles: <Bundle>[]);
    }

    final bundles = bundlesRaw
        .whereType<Map>()
        .map((raw) => _bundleFromJson(Map<String, dynamic>.from(raw)))
        .toList(growable: false);

    return SyncFetchResult(bundles: bundles);
  }

  Map<String, Object?> _bundleToJson(Bundle bundle) {
    return <String, Object?>{
      'bundleId': bundle.bundleId,
      'type': bundle.type,
      'sourceNodeId': bundle.sourceNodeId,
      'destinationNodeId': bundle.destinationNodeId,
      'destinationScope': bundle.destinationScope.name,
      'priority': bundle.priority.name,
      'ackForBundleId': bundle.ackForBundleId,
      'payload': bundle.payload,
      'payloadRef': bundle.payloadReference,
      'signature': bundle.signature,
      'appId': bundle.appId,
      'createdAtMs': bundle.createdAt.millisecondsSinceEpoch,
      'expiresAtMs': bundle.expiresAtOverride?.millisecondsSinceEpoch,
      'ttlSeconds': bundle.ttlSeconds,
      'hopCount': bundle.hopCount,
      'acknowledged': bundle.acknowledged,
      'sentAtMs': bundle.sentAt?.millisecondsSinceEpoch,
      'failedAttempts': bundle.failedAttempts,
      'lastError': bundle.lastError,
    };
  }

  Bundle _bundleFromJson(Map<String, dynamic> json) {
    return Bundle(
      bundleId: json['bundleId'] as String,
      type: json['type'] as String,
      sourceNodeId: json['sourceNodeId'] as String,
      destinationNodeId: json['destinationNodeId'] as String?,
      destinationScope: Bundle.destinationScopeFromWire(
        json['destinationScope'] as String?,
      ),
      priority: Bundle.priorityFromWire(json['priority'] as String?),
      ackForBundleId: json['ackForBundleId'] as String?,
      payload: json['payload'] as String?,
      payloadReference: json['payloadRef'] as String?,
      signature: json['signature'] as String?,
      appId: (json['appId'] as String?) ?? 'offlimu.chat',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAtMs'] as int,
      ),
      expiresAtOverride: (json['expiresAtMs'] as int?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['expiresAtMs'] as int),
      ttlSeconds: json['ttlSeconds'] as int,
      hopCount: (json['hopCount'] as int?) ?? 0,
      acknowledged: (json['acknowledged'] as bool?) ?? false,
      sentAt: (json['sentAtMs'] as int?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['sentAtMs'] as int),
      failedAttempts: (json['failedAttempts'] as int?) ?? 0,
      lastError: json['lastError'] as String?,
    );
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
  }

  List<String> _asStringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw.whereType<String>().toList(growable: false);
  }

  Bundle _buildConfirmationFor(Bundle uploaded) {
    final now = DateTime.now();
    return Bundle(
      bundleId: 'server-ack-${uploaded.bundleId}-${now.microsecondsSinceEpoch}',
      type: Bundle.typeAck,
      sourceNodeId: 'server-gateway',
      destinationNodeId: uploaded.sourceNodeId,
      destinationScope: BundleDestinationScope.direct,
      priority: BundlePriority.normal,
      ackForBundleId: uploaded.bundleId,
      payload: null,
      appId: uploaded.appId,
      createdAt: now,
      ttlSeconds: 600,
      acknowledged: true,
    );
  }

  Bundle _buildRejectionFor(Bundle uploaded) {
    final now = DateTime.now();
    return Bundle(
      bundleId:
          'server-reject-${uploaded.bundleId}-${now.microsecondsSinceEpoch}',
      type: Bundle.typeSyncRejection,
      sourceNodeId: 'server-gateway',
      destinationNodeId: uploaded.sourceNodeId,
      destinationScope: BundleDestinationScope.direct,
      priority: BundlePriority.normal,
      ackForBundleId: uploaded.bundleId,
      payload: 'Rejected by server policy (mock)',
      appId: uploaded.appId,
      createdAt: now,
      ttlSeconds: 600,
      acknowledged: true,
    );
  }
}
