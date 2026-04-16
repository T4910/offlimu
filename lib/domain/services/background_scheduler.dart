abstract interface class BackgroundScheduler {
  Future<void> registerPeriodicTask({
    required String taskId,
    required Duration frequency,
  });

  Future<void> unregisterTask(String taskId);
}
