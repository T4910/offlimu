import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/core/error/app_error_log_store.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(localNodeIdentityProvider);
    final appConfig = ref.watch(appConfigProvider);
    final gatewayEnabled = ref.watch(gatewayEnabledProvider);
    final errorLogStore = ref.watch(appErrorLogStoreProvider);
    final publicIdentityAsync = ref.watch(nodePublicIdentityProvider);
    final nodeIdentityStore = ref.read(nodeIdentityStoreProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Node', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  SelectableText('Display Name: ${identity.displayName}'),
                  SelectableText('Node ID: ${identity.nodeId}'),
                  const SizedBox(height: 6),
                  SelectableText('Environment: ${appConfig.environment.name}'),
                  SelectableText('TCP Port: ${appConfig.transportPort}'),
                  SelectableText('Discovery Port: ${appConfig.discoveryPort}'),
                  const SizedBox(height: 10),
                  publicIdentityAsync.when(
                    loading: () => const Text('Generating public identity...'),
                    error: (error, stackTrace) =>
                        Text('Public identity error: $error'),
                    data: (publicIdentity) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Public Identity',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          'Fingerprint: ${publicIdentity.publicKeyFingerprint}',
                        ),
                        SelectableText(
                          'Public Key: ${publicIdentity.publicKeyBase64}',
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () async {
                            await nodeIdentityStore.rotate(
                              nodeId: identity.nodeId,
                              displayName: identity.displayName,
                            );
                            ref.invalidate(nodePublicIdentityProvider);
                          },
                          child: const Text('Rotate Keypair'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile.adaptive(
              value: gatewayEnabled,
              title: const Text('Enable Gateway Sync'),
              subtitle: const Text('Persisted across app restarts.'),
              onChanged: (value) =>
                  ref.read(gatewayEnabledProvider.notifier).state = value,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Diagnostics',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<List<AppErrorLogEntry>>(
                    valueListenable: errorLogStore.entries,
                    builder: (context, entries, _) {
                      if (entries.isEmpty) {
                        return const Text('No uncaught errors recorded yet.');
                      }

                      return Column(
                        children: entries.reversed
                            .take(5)
                            .map<Widget>(
                              (entry) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(entry.source),
                                subtitle: Text(
                                  '${entry.timestamp.toIso8601String()}\n${entry.error}',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () async {
                        await errorLogStore.clear();
                      },
                      child: const Text('Clear Error Log'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
