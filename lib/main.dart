import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/app/app.dart';
import 'package:offlimu/core/error/app_error_boundary.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installAppWideErrorHandling();
  await appErrorLogStore.initialize();
  runApp(const ProviderScope(child: OfflimuApp()));
}
