import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offlimu/core/error/app_error_log_store.dart';

class AppUnhandledError {
  const AppUnhandledError({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;
}

final ValueNotifier<AppUnhandledError?> appUnhandledErrorNotifier =
    ValueNotifier<AppUnhandledError?>(null);

final AppErrorLogStore appErrorLogStore = AppErrorLogStore();

void installAppWideErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _recordUnhandledError(
      'flutter',
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    _recordUnhandledError('platform', error, stackTrace);
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    final String message = kDebugMode
        ? details.exceptionAsString()
        : 'Unexpected UI error';

    return ColoredBox(
      color: const Color(0xFFFBE9E7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'OffLiMU encountered an error.\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  };
}

void _recordUnhandledError(String source, Object error, StackTrace stackTrace) {
  debugPrint('Unhandled error: $error');
  debugPrintStack(stackTrace: stackTrace);
  appErrorLogStore.record(source: source, error: error, stackTrace: stackTrace);
  appUnhandledErrorNotifier.value = AppUnhandledError(
    error: error,
    stackTrace: stackTrace,
  );
}

class AppErrorBoundaryOverlay extends StatelessWidget {
  const AppErrorBoundaryOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUnhandledError?>(
      valueListenable: appUnhandledErrorNotifier,
      builder: (context, error, _) {
        if (error == null) {
          return child;
        }

        return Material(
          color: const Color(0xFFF9F1EE),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Something went wrong',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'An unexpected error occurred in OffLiMU. '
                            'You can dismiss this and continue.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          if (kDebugMode)
                            SelectableText(
                              error.error.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () {
                                appUnhandledErrorNotifier.value = null;
                              },
                              child: const Text('Dismiss'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
