import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/node_runtime/sync_engine.dart';

class GatewaySyncCoordinatorStatus {
  const GatewaySyncCoordinatorStatus({
    this.enabled = false,
    this.deadLettered = false,
    this.consecutiveFailures = 0,
    this.nextDelaySeconds,
  });

  final bool enabled;
  final bool deadLettered;
  final int consecutiveFailures;
  final int? nextDelaySeconds;
}

class GatewaySyncCoordinator {
  GatewaySyncCoordinator({
    required SyncEngine syncEngine,
    required void Function(AsyncValue<SyncRunResult>) onState,
    required void Function(GatewaySyncCoordinatorStatus) onStatus,
    this.interval = const Duration(seconds: 20),
    this.maxConsecutiveFailures = 5,
    this.maxBackoff = const Duration(minutes: 5),
  })  : _syncEngine = syncEngine,
        _onState = onState,
      _onStatus = onStatus;

  final SyncEngine _syncEngine;
  final void Function(AsyncValue<SyncRunResult>) _onState;
  final void Function(GatewaySyncCoordinatorStatus) _onStatus;
  final Duration interval;
  final int maxConsecutiveFailures;
  final Duration maxBackoff;

  Timer? _timer;
  bool _enabled = false;
  bool _deadLettered = false;
  int _consecutiveFailures = 0;
  Duration? _nextDelay;

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (enabled) {
      _deadLettered = false;
      _consecutiveFailures = 0;
      _nextDelay = null;
      _emitStatus();
      await _runSync(gatewayEnabled: true, isAuto: true);
      return;
    }

    _cancelTimer();
    _consecutiveFailures = 0;
    _deadLettered = false;
    _nextDelay = null;
    _emitStatus();
  }

  Future<void> runManual({required bool gatewayEnabled}) {
    return _runSync(gatewayEnabled: gatewayEnabled, isAuto: false);
  }

  Future<void> dispose() async {
    _cancelTimer();
  }

  Future<void> _runSync({
    required bool gatewayEnabled,
    required bool isAuto,
  }) async {
    if (isAuto) {
      if (!_enabled || _deadLettered) {
        return;
      }
      _cancelTimer();
    }

    _onState(const AsyncValue<SyncRunResult>.loading());
    try {
      final result = await _syncEngine.syncNow(gatewayEnabled: gatewayEnabled);
      _onState(AsyncValue<SyncRunResult>.data(result));
      _consecutiveFailures = 0;
      _deadLettered = false;
      _nextDelay = interval;
      _emitStatus();

      if (isAuto && _enabled) {
        _scheduleNext(_nextDelay!);
      }
    } catch (error, stackTrace) {
      _onState(AsyncValue<SyncRunResult>.error(error, stackTrace));

      if (!isAuto || !_enabled) {
        return;
      }

      _consecutiveFailures += 1;
      if (_consecutiveFailures >= maxConsecutiveFailures) {
        _deadLettered = true;
        _nextDelay = null;
        _emitStatus();
        _onState(
          AsyncValue<SyncRunResult>.error(
            StateError(
              'Auto-sync dead-lettered after $_consecutiveFailures '
              'consecutive failures. Toggle gateway sync off/on to reset.',
            ),
            StackTrace.current,
          ),
        );
        return;
      }

      _nextDelay = _computeBackoffDelay(_consecutiveFailures);
      _emitStatus();
      _scheduleNext(_nextDelay!);
    }
  }

  Duration _computeBackoffDelay(int failures) {
    final int multiplier = 1 << (failures - 1);
    final int delaySeconds = interval.inSeconds * multiplier;
    final int maxSeconds = maxBackoff.inSeconds;
    return Duration(seconds: delaySeconds > maxSeconds ? maxSeconds : delaySeconds);
  }

  void _scheduleNext(Duration delay) {
    _timer = Timer(delay, () {
      unawaited(_runSync(gatewayEnabled: true, isAuto: true));
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _emitStatus() {
    _onStatus(
      GatewaySyncCoordinatorStatus(
        enabled: _enabled,
        deadLettered: _deadLettered,
        consecutiveFailures: _consecutiveFailures,
        nextDelaySeconds: _nextDelay?.inSeconds,
      ),
    );
  }
}
