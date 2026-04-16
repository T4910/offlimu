import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/sync_job_history_entry.dart';
import 'package:offlimu/domain/repositories/bundle_repository.dart';
import 'package:offlimu/domain/repositories/sync_job_repository.dart';
import 'package:offlimu/domain/services/device_conditions_service.dart';
import 'package:offlimu/domain/services/logger_service.dart';
import 'package:offlimu/domain/services/sync_api.dart';

class SyncDevicePolicy {
  const SyncDevicePolicy({
    this.allowMeteredNetwork = true,
    this.minBatteryPercent = 20,
    this.requireChargingWhenLowBattery = true,
  });

  final bool allowMeteredNetwork;
  final int minBatteryPercent;
  final bool requireChargingWhenLowBattery;
}

class SyncRunResult {
  const SyncRunResult({
    required this.uploadedCount,
    required this.downloadedCount,
    required this.completedAt,
    required this.mockMode,
    required this.gatewayEnabled,
    required this.internetReachable,
  });

  final int uploadedCount;
  final int downloadedCount;
  final DateTime completedAt;
  final bool mockMode;
  final bool gatewayEnabled;
  final bool internetReachable;
}

class SyncEngine {
  SyncEngine({
    required String localNodeId,
    required BundleRepository bundles,
    required SyncApi syncApi,
    required SyncJobRepository syncJobs,
    required DeviceConditionsService deviceConditions,
    LoggerService? logger,
    this.devicePolicy = const SyncDevicePolicy(),
    this.maxHopCount = 5,
  }) : _localNodeId = localNodeId,
       _bundles = bundles,
       _syncApi = syncApi,
       _syncJobs = syncJobs,
       _deviceConditions = deviceConditions,
       _logger = logger;

  final String _localNodeId;
  final BundleRepository _bundles;
  final SyncApi _syncApi;
  final SyncJobRepository _syncJobs;
  final DeviceConditionsService _deviceConditions;
  final LoggerService? _logger;
  final SyncDevicePolicy devicePolicy;
  final int maxHopCount;

  DateTime? _lastSyncAt;

  Future<SyncRunResult> syncNow({required bool gatewayEnabled}) async {
    final DateTime startedAt = DateTime.now();
    int uploadedCount = 0;
    int downloadedCount = 0;
    String? errorMessage;

    _logger?.info(
      'sync_started',
      scope: 'sync',
      fields: {'gatewayEnabled': gatewayEnabled, 'nodeId': _localNodeId},
    );

    if (!gatewayEnabled) {
      errorMessage = 'Gateway sync is disabled by user preference.';
      await _persistRun(
        startedAt: startedAt,
        completedAt: DateTime.now(),
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        success: false,
        mockMode: _isMockMode(),
        gatewayEnabled: gatewayEnabled,
        internetReachable: false,
        errorMessage: errorMessage,
      );
      _logger?.warning('sync_skipped_gateway_disabled', scope: 'sync');
      throw StateError('Gateway sync is disabled by user preference.');
    }

    final bool mockMode = _isMockMode();

    final snapshot = await _deviceConditions.read();
    final bool internetReachable = snapshot.internetReachable;
    final bool networkAllowed = _isNetworkAllowed(snapshot.connectionType);
    final bool batteryAllowed = _isBatteryAllowed(snapshot);

    if (!internetReachable) {
      errorMessage = 'Internet not reachable. Sync skipped.';
      await _persistRun(
        startedAt: startedAt,
        completedAt: DateTime.now(),
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        success: false,
        mockMode: mockMode,
        gatewayEnabled: gatewayEnabled,
        internetReachable: internetReachable,
        errorMessage: errorMessage,
      );
      _logger?.warning('sync_skipped_internet_unreachable', scope: 'sync');
      throw StateError('Internet not reachable. Sync skipped.');
    }

    if (!networkAllowed) {
      errorMessage =
          'Sync skipped by policy: metered network is disabled (wifi/ethernet required).';
      await _persistRun(
        startedAt: startedAt,
        completedAt: DateTime.now(),
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        success: false,
        mockMode: _isMockMode(),
        gatewayEnabled: gatewayEnabled,
        internetReachable: internetReachable,
        errorMessage: errorMessage,
      );
      _logger?.warning(
        'sync_skipped_network_policy',
        scope: 'sync',
        fields: {'connectionType': snapshot.connectionType.name},
      );
      throw StateError(errorMessage);
    }

    if (!batteryAllowed) {
      final battery = snapshot.batteryLevelPercent;
      errorMessage =
          'Sync skipped by battery policy: battery $battery% is below ${devicePolicy.minBatteryPercent}% and device is not charging.';
      await _persistRun(
        startedAt: startedAt,
        completedAt: DateTime.now(),
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        success: false,
        mockMode: _isMockMode(),
        gatewayEnabled: gatewayEnabled,
        internetReachable: internetReachable,
        errorMessage: errorMessage,
      );
      _logger?.warning(
        'sync_skipped_battery_policy',
        scope: 'sync',
        fields: {
          'batteryLevelPercent': battery,
          'isCharging': snapshot.isCharging,
        },
      );
      throw StateError(errorMessage);
    }

    try {
      final List<Bundle> pending = await _bundles.getPendingBundles();
      final DateTime now = DateTime.now();
      final List<Bundle> outbound = pending
          .where((bundle) => bundle.sourceNodeId == _localNodeId)
          .where((bundle) => !bundle.isAck)
          .where((bundle) => !_isExpired(bundle, now))
          .where((bundle) => bundle.hopCount < maxHopCount)
          .toList(growable: false);

      for (final expired
          in pending
              .where((bundle) => bundle.sourceNodeId == _localNodeId)
              .where((bundle) => !bundle.isAck)
              .where((bundle) => _isExpired(bundle, now))) {
        await _bundles.markRejected(
          expired.bundleId,
          reason: 'Bundle expired before gateway sync (TTL exceeded).',
        );
      }

      for (final overHop
          in pending
              .where((bundle) => bundle.sourceNodeId == _localNodeId)
              .where((bundle) => !bundle.isAck)
              .where((bundle) => bundle.hopCount >= maxHopCount)) {
        await _bundles.markRejected(
          overHop.bundleId,
          reason: 'Bundle exceeded max hop count ($maxHopCount).',
        );
      }

      uploadedCount = outbound.length;
      final uploadResult = await _syncApi.uploadBundles(outbound);

      final acknowledgedIds = uploadResult.acknowledgedBundleIds.toSet();
      final rejectedById = {
        for (final rejection in uploadResult.rejections)
          rejection.bundleId: rejection.reason,
      };

      for (final bundle in outbound) {
        final rejectedReason = rejectedById[bundle.bundleId];
        if (rejectedReason != null) {
          await _bundles.markRejected(bundle.bundleId, reason: rejectedReason);
          continue;
        }

        if (acknowledgedIds.contains(bundle.bundleId)) {
          await _bundles.markAcknowledged(bundle.bundleId);
          continue;
        }

        await _bundles.markSent(bundle.bundleId);
      }

      final DateTime since =
          _lastSyncAt ?? DateTime.now().subtract(const Duration(days: 1));
      final fetchResult = await _syncApi.fetchRemoteBundles(since: since);
      final List<Bundle> inbound = fetchResult.bundles
          .where((bundle) => !_isExpired(bundle, now))
          .where((bundle) => bundle.hopCount <= maxHopCount)
          .toList(growable: false);
      downloadedCount = inbound.length;

      for (final bundle in inbound) {
        await _bundles.save(bundle);

        if (bundle.isAck) {
          await _bundles.recordAckReceipt(bundle);
          await _bundles.markAcknowledged(bundle.bundleId);
          final ackForId = bundle.ackForBundleId;
          if (ackForId != null) {
            await _bundles.markAcknowledged(ackForId);
          }
          continue;
        }

        if (bundle.isSyncRejection) {
          await _bundles.markAcknowledged(bundle.bundleId);
          final rejectedId = bundle.ackForBundleId;
          if (rejectedId != null) {
            await _bundles.markRejected(
              rejectedId,
              reason: bundle.payload ?? 'Rejected by sync server',
            );
          }
          continue;
        }

        if (bundle.sourceNodeId != _localNodeId) {
          await _bundles.markAcknowledged(bundle.bundleId);
        }
      }

      _lastSyncAt = DateTime.now();
      await _persistRun(
        startedAt: startedAt,
        completedAt: _lastSyncAt!,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        success: true,
        mockMode: mockMode,
        gatewayEnabled: gatewayEnabled,
        internetReachable: internetReachable,
      );

      _logger?.info(
        'sync_completed',
        scope: 'sync',
        fields: {
          'uploadedCount': uploadedCount,
          'downloadedCount': downloadedCount,
          'mockMode': mockMode,
        },
      );

      return SyncRunResult(
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        completedAt: _lastSyncAt!,
        mockMode: mockMode,
        gatewayEnabled: gatewayEnabled,
        internetReachable: internetReachable,
      );
    } catch (error) {
      errorMessage = error.toString();
      await _persistRun(
        startedAt: startedAt,
        completedAt: DateTime.now(),
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        success: false,
        mockMode: mockMode,
        gatewayEnabled: gatewayEnabled,
        internetReachable: internetReachable,
        errorMessage: errorMessage,
      );
      _logger?.error(
        'sync_failed',
        scope: 'sync',
        error: error,
        fields: {
          'uploadedCount': uploadedCount,
          'downloadedCount': downloadedCount,
        },
      );
      rethrow;
    }
  }

  bool _isMockMode() {
    return _syncApi.mockMode;
  }

  bool _isExpired(Bundle bundle, DateTime now) {
    return now.isAfter(bundle.expiresAt);
  }

  bool _isNetworkAllowed(DeviceConnectionType connectionType) {
    if (devicePolicy.allowMeteredNetwork) {
      return true;
    }
    return connectionType == DeviceConnectionType.wifi ||
        connectionType == DeviceConnectionType.ethernet;
  }

  bool _isBatteryAllowed(DeviceConditionsSnapshot snapshot) {
    final level = snapshot.batteryLevelPercent;
    if (level == null) {
      return true;
    }
    if (level >= devicePolicy.minBatteryPercent) {
      return true;
    }
    if (!devicePolicy.requireChargingWhenLowBattery) {
      return true;
    }
    return snapshot.isCharging;
  }

  Future<void> _persistRun({
    required DateTime startedAt,
    required DateTime completedAt,
    required int uploadedCount,
    required int downloadedCount,
    required bool success,
    required bool mockMode,
    required bool gatewayEnabled,
    required bool internetReachable,
    String? errorMessage,
  }) {
    return _syncJobs.saveRun(
      SyncJobHistoryEntry(
        startedAt: startedAt,
        completedAt: completedAt,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        success: success,
        mockMode: mockMode,
        gatewayEnabled: gatewayEnabled,
        internetReachable: internetReachable,
        errorMessage: errorMessage,
      ),
    );
  }
}
