import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/sync_job_history_entry.dart';

class SyncPage extends ConsumerWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncJobsAsync = ref.watch(recentSyncJobsProvider);
    final syncState = ref.watch(syncRunStateProvider);
    final gatewayEnabled = ref.watch(gatewayEnabledProvider);
    final gatewaySyncStatus = ref.watch(gatewaySyncStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FilledButton(
                    onPressed: () async {
                      await ref
                          .read(gatewaySyncCoordinatorProvider)
                          .runManual(gatewayEnabled: gatewayEnabled);
                    },
                    child: const Text('Sync Now'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: gatewayEnabled,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Gateway Sync'),
                    onChanged: (value) =>
                        ref.read(gatewayEnabledProvider.notifier).state = value,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Auto-sync: ${gatewaySyncStatus.enabled ? 'enabled' : 'disabled'} • '
                    'failures: ${gatewaySyncStatus.consecutiveFailures} • '
                    '${gatewaySyncStatus.deadLettered ? 'dead-lettered' : 'active'}'
                    '${gatewaySyncStatus.nextDelaySeconds == null ? '' : ' • next attempt in ${gatewaySyncStatus.nextDelaySeconds}s'}',
                  ),
                  const SizedBox(height: 8),
                  if (syncState == null)
                    const Text('No sync run yet.')
                  else
                    syncState.when(
                      loading: () => const Text('Sync in progress...'),
                      error: (error, stackTrace) => Text('Sync failed: $error'),
                      data: (result) => Text(
                        'Uploaded: ${result.uploadedCount}, '
                        'Downloaded: ${result.downloadedCount} '
                        '${result.mockMode ? '(mock mode)' : ''}\n'
                        'Gateway: ${result.gatewayEnabled ? 'enabled' : 'disabled'}, '
                        'Internet: ${result.internetReachable ? 'reachable' : 'offline'}',
                      ),
                    ),
                ],
              ),
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
                    'Recent Sync Jobs',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  syncJobsAsync.when(
                    loading: () => const Text('Loading sync history...'),
                    error: (error, stackTrace) => Text('History error: $error'),
                    data: (List<SyncJobHistoryEntry> jobs) {
                      if (jobs.isEmpty) {
                        return const Text('No sync runs recorded yet.');
                      }
                      return Column(
                        children: jobs
                            .map<Widget>(
                              (job) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${job.success ? 'success' : 'failed'} • '
                                  'up:${job.uploadedCount} down:${job.downloadedCount}',
                                ),
                                subtitle: Text(
                                  job.completedAt.toIso8601String(),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
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
