import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/node_identity.dart';
import 'package:offlimu/features/debug/presentation/debug_page.dart';
import 'package:offlimu/node_runtime/node_runtime_state.dart';

void main() {
  testWidgets('Debug console renders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          nodeRuntimeStateProvider.overrideWithValue(
            AsyncValue<NodeRuntimeState>.data(
              NodeRuntimeState(
                identity: const NodeIdentity(
                  nodeId: 'node-local-001',
                  displayName: 'OffLiMU Node',
                ),
                health: RuntimeHealth.connected,
                discoveredPeers: 1,
                pendingBundles: 0,
                gatewayEnabled: true,
                telemetry: const RuntimeTelemetry(),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: DebugPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OffLiMU Debug Console'), findsOneWidget);
  });
}
