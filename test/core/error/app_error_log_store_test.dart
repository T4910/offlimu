import 'package:flutter_test/flutter_test.dart';
import 'package:offlimu/core/error/app_error_log_store.dart';

void main() {
  test('app error log store trims to max entries', () async {
    final store = AppErrorLogStore(maxEntries: 3);

    store.record(
      source: 'flutter',
      error: StateError('first'),
      stackTrace: StackTrace.current,
    );
    store.record(
      source: 'platform',
      error: StateError('second'),
      stackTrace: StackTrace.current,
    );
    store.record(
      source: 'platform',
      error: StateError('third'),
      stackTrace: StackTrace.current,
    );
    store.record(
      source: 'flutter',
      error: StateError('fourth'),
      stackTrace: StackTrace.current,
    );

    expect(store.entries.value, hasLength(3));
    expect(store.entries.value.first.error, contains('second'));
    expect(store.entries.value.last.error, contains('fourth'));
  });

  test('app error log store clear removes entries', () async {
    final store = AppErrorLogStore(maxEntries: 3);

    store.record(
      source: 'flutter',
      error: StateError('first'),
      stackTrace: StackTrace.current,
    );

    await store.clear();

    expect(store.entries.value, isEmpty);
  });
}
