abstract interface class LoggerService {
  void info(
    String message, {
    String scope = 'app',
    Map<String, Object?> fields = const <String, Object?>{},
  });

  void warning(
    String message, {
    String scope = 'app',
    Map<String, Object?> fields = const <String, Object?>{},
  });

  void error(
    String message, {
    String scope = 'app',
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const <String, Object?>{},
  });
}
