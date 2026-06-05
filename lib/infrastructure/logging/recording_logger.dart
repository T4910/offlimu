import 'package:offlimu/core/debug/runtime_log_store.dart';
import 'package:offlimu/domain/services/logger_service.dart';
import 'package:offlimu/infrastructure/logging/structured_logger.dart';

class RecordingLogger implements LoggerService {
  RecordingLogger({required RuntimeLogStore store, LoggerService? delegate})
    : _store = store,
      _delegate = delegate ?? const StructuredLogger();

  static const Set<String> _redactedFieldNames = <String>{
    'payload',
    'signature',
    'token',
    'authorization',
    'password',
    'privateKey',
  };

  final RuntimeLogStore _store;
  final LoggerService _delegate;

  @override
  void info(
    String message, {
    String scope = 'app',
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    _record('INFO', message, scope: scope, fields: fields);
    _delegate.info(message, scope: scope, fields: fields);
  }

  @override
  void warning(
    String message, {
    String scope = 'app',
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    _record('WARN', message, scope: scope, fields: fields);
    _delegate.warning(message, scope: scope, fields: fields);
  }

  @override
  void error(
    String message, {
    String scope = 'app',
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    _record(
      'ERROR',
      message,
      scope: scope,
      fields: fields,
      error: error,
      stackTrace: stackTrace,
    );
    _delegate.error(
      message,
      scope: scope,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  void _record(
    String level,
    String message, {
    required String scope,
    required Map<String, Object?> fields,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _store.record(
      RuntimeLogEntry(
        timestamp: DateTime.now(),
        level: level,
        scope: scope,
        message: message,
        fields: _sanitize(fields),
        error: error?.toString(),
        stackTrace: stackTrace?.toString(),
      ),
    );
  }

  Map<String, Object?> _sanitize(Map<String, Object?> fields) {
    final result = <String, Object?>{};
    fields.forEach((key, value) {
      if (_redactedFieldNames.contains(key)) {
        result[key] = '<redacted>';
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}
