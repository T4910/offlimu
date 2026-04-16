import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppErrorLogEntry {
  const AppErrorLogEntry({
    required this.timestamp,
    required this.source,
    required this.error,
    required this.stackTrace,
  });

  final DateTime timestamp;
  final String source;
  final String error;
  final String stackTrace;

  Map<String, Object?> toJson() => <String, Object?>{
    'timestamp': timestamp.toIso8601String(),
    'source': source,
    'error': error,
    'stackTrace': stackTrace,
  };

  factory AppErrorLogEntry.fromJson(Map<String, Object?> json) {
    return AppErrorLogEntry(
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: json['source'] as String? ?? 'unknown',
      error: json['error'] as String? ?? 'Unknown error',
      stackTrace: json['stackTrace'] as String? ?? '',
    );
  }
}

class AppErrorLogStore {
  AppErrorLogStore({this.maxEntries = 50});

  final int maxEntries;
  final ValueNotifier<List<AppErrorLogEntry>> entries =
      ValueNotifier<List<AppErrorLogEntry>>(<AppErrorLogEntry>[]);

  final List<AppErrorLogEntry> _pendingEntries = <AppErrorLogEntry>[];
  File? _logFile;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final Directory docs = await getApplicationDocumentsDirectory();
    _logFile = File(p.join(docs.path, 'offlimu_error_log.json'));

    List<AppErrorLogEntry> loadedEntries = <AppErrorLogEntry>[];
    if (await _logFile!.exists()) {
      try {
        final String raw = await _logFile!.readAsString();
        if (raw.trim().isNotEmpty) {
          final Object? parsed = jsonDecode(raw);
          if (parsed is List) {
            loadedEntries = parsed
                .whereType<Map>()
                .map(
                  (dynamic item) => AppErrorLogEntry.fromJson(
                    Map<String, Object?>.from(item as Map),
                  ),
                )
                .toList(growable: false);
          }
        }
      } catch (error, stackTrace) {
        debugPrint('Failed to read error log: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final List<AppErrorLogEntry> merged = <AppErrorLogEntry>[
      ...loadedEntries,
      ..._pendingEntries,
    ];
    entries.value = _trimToLimit(merged);
    _pendingEntries.clear();
    _initialized = true;
    await _persist();
  }

  void record({
    required String source,
    required Object error,
    required StackTrace stackTrace,
  }) {
    final AppErrorLogEntry entry = AppErrorLogEntry(
      timestamp: DateTime.now(),
      source: source,
      error: error.toString(),
      stackTrace: stackTrace.toString(),
    );

    entries.value = _trimToLimit(<AppErrorLogEntry>[...entries.value, entry]);

    if (_initialized) {
      unawaited(_persist());
    } else {
      _pendingEntries.add(entry);
    }
  }

  Future<void> clear() async {
    entries.value = <AppErrorLogEntry>[];
    _pendingEntries.clear();
    if (_initialized) {
      await _persist();
    }
  }

  Future<void> _persist() async {
    final File? logFile = _logFile;
    if (logFile == null) {
      return;
    }

    try {
      await logFile.parent.create(recursive: true);
      await logFile.writeAsString(
        jsonEncode(entries.value.map((entry) => entry.toJson()).toList()),
        flush: true,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to persist error log: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<AppErrorLogEntry> _trimToLimit(List<AppErrorLogEntry> source) {
    if (source.length <= maxEntries) {
      return List<AppErrorLogEntry>.unmodifiable(source);
    }
    return List<AppErrorLogEntry>.unmodifiable(
      source.sublist(source.length - maxEntries),
    );
  }
}
