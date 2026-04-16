import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/app/router/app_router.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/core/error/app_error_boundary.dart';
import 'package:offlimu/core/theme/app_theme.dart';

class OfflimuApp extends ConsumerWidget {
  const OfflimuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gatewaySyncPreferenceBootstrapProvider);
    ref.watch(backgroundTaskBootstrapProvider);
    ref.watch(nodeIdentityBootstrapProvider);

    return MaterialApp.router(
      title: 'OffLiMU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) =>
          AppErrorBoundaryOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
