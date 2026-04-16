import 'dart:convert';
import 'dart:developer' as developer;

import 'package:offlimu/domain/services/logger_service.dart';

class StructuredLogger implements LoggerService {
  const StructuredLogger();

  static const Set<String> _redactedFieldNames = <String>{
    'payload',
    'signature',
    'token',
    'authorization',
    'password',
    'privateKey',
  };

  @override
  void info(
    String message, {
    String scope = 'app',
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    _log('INFO', message, scope: scope, fields: fields);
  }

  @override
  void warning(
    String message, {
    String scope = 'app',
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    _log('WARN', message, scope: scope, fields: fields);
  }

  @override
  void error(
    String message, {
    String scope = 'app',
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    _log(
      'ERROR',
      message,
      scope: scope,
      fields: fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log(
    String level,
    String message, {
    required String scope,
    required Map<String, Object?> fields,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final event = <String, Object?>{
      'ts': DateTime.now().toIso8601String(),
      'level': level,
      'scope': scope,
      'message': message,
      'fields': _sanitize(fields),
    };
    if (error != null) {
      event['error'] = error.toString();
    }
    if (stackTrace != null) {
      event['stackTrace'] = stackTrace.toString();
    }
    developer.log(jsonEncode(event), name: 'offlimu');
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
