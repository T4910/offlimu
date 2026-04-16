import 'dart:async';

import 'package:offlimu/domain/services/background_scheduler.dart';

class InAppBackgroundScheduler implements BackgroundScheduler {
  InAppBackgroundScheduler({Future<void> Function(String taskId)? onTask})
    : _onTask = onTask;

  final Future<void> Function(String taskId)? _onTask;
  final Map<String, Timer> _timers = <String, Timer>{};

  @override
  Future<void> registerPeriodicTask({
    required String taskId,
    required Duration frequency,
  }) async {
    if (frequency <= Duration.zero) {
      throw ArgumentError.value(
        frequency,
        'frequency',
        'Frequency must be greater than zero.',
      );
    }

    _timers.remove(taskId)?.cancel();
    _timers[taskId] = Timer.periodic(frequency, (_) {
      final callback = _onTask;
      if (callback != null) {
        unawaited(callback(taskId));
      }
    });
  }

  @override
  Future<void> unregisterTask(String taskId) async {
    _timers.remove(taskId)?.cancel();
  }

  Future<void> dispose() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
