import 'package:flutter/foundation.dart';

class RuntimeLogEntry {
  const RuntimeLogEntry({
    required this.timestamp,
    required this.level,
    required this.scope,
    required this.message,
    required this.fields,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final String level;
  final String scope;
  final String message;
  final Map<String, Object?> fields;
  final String? error;
  final String? stackTrace;
}

class RuntimeLogStore {
  RuntimeLogStore({this.maxEntries = 200});

  final int maxEntries;
  final ValueNotifier<List<RuntimeLogEntry>> entries =
      ValueNotifier<List<RuntimeLogEntry>>(<RuntimeLogEntry>[]);

  void record(RuntimeLogEntry entry) {
    entries.value = _trim(<RuntimeLogEntry>[...entries.value, entry]);
  }

  void clear() {
    entries.value = <RuntimeLogEntry>[];
  }

  void dispose() {
    entries.dispose();
  }

  List<RuntimeLogEntry> _trim(List<RuntimeLogEntry> source) {
    if (source.length <= maxEntries) {
      return List<RuntimeLogEntry>.unmodifiable(source);
    }
    return List<RuntimeLogEntry>.unmodifiable(
      source.sublist(source.length - maxEntries),
    );
  }
}
