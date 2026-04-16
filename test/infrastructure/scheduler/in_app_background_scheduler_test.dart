import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/infrastructure/scheduler/in_app_background_scheduler.dart';

void main() {
  test('runs periodic task and stops after unregister', () async {
    final List<String> firedTasks = <String>[];
    final scheduler = InAppBackgroundScheduler(
      onTask: (taskId) async {
        firedTasks.add(taskId);
      },
    );

    await scheduler.registerPeriodicTask(
      taskId: 'sync',
      frequency: const Duration(milliseconds: 20),
    );

    await Future<void>.delayed(const Duration(milliseconds: 90));

    expect(firedTasks, isNotEmpty);

    await scheduler.unregisterTask('sync');
    final countAfterUnregister = firedTasks.length;

    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(firedTasks.length, countAfterUnregister);

    await scheduler.dispose();
  });

  test('throws when frequency is zero', () async {
    final scheduler = InAppBackgroundScheduler();

    expect(
      () => scheduler.registerPeriodicTask(
        taskId: 'invalid',
        frequency: Duration.zero,
      ),
      throwsArgumentError,
    );

    await scheduler.dispose();
  });
}
