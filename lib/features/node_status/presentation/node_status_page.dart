import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/core/error/app_error_log_store.dart';
import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:offlimu/domain/entities/peer_contact.dart';
import 'package:offlimu/domain/entities/sync_job_history_entry.dart';

class NodeStatusPage extends ConsumerStatefulWidget {
  const NodeStatusPage({super.key});

  @override
  ConsumerState<NodeStatusPage> createState() => _NodeStatusPageState();
}

class _NodeStatusPageState extends ConsumerState<NodeStatusPage> {
  String _ackFilter = '';
  bool _duplicatesOnly = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(gatewaySyncCoordinatorProvider);

    final runtimeAsync = ref.watch(nodeRuntimeStateProvider);
    final peerContactsAsync = ref.watch(peerContactsProvider);
    final syncJobsAsync = ref.watch(recentSyncJobsProvider);
    final ackEventsAsync = ref.watch(recentAckEventsProvider);
    final ackEvents = ackEventsAsync.valueOrNull ?? const <AckAuditEvent>[];
    final duplicateAckCount = ackEvents.fold<int>(
      0,
      (sum, event) => sum + event.duplicateCount,
    );
    final duplicateAckBundles = ackEvents
        .where((event) => event.duplicateCount > 0)
        .length;
    final syncState = ref.watch(syncRunStateProvider);
    final gatewayEnabled = ref.watch(gatewayEnabledProvider);
    final gatewaySyncStatus = ref.watch(gatewaySyncStatusProvider);
    final errorLogStore = ref.watch(appErrorLogStoreProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('OffLiMU Node Status')),
      body: runtimeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (runtime) => ListView(
          padding: const EdgeInsets.all(12),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      runtime.identity.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    SelectableText('Node ID: ${runtime.identity.nodeId}'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _StatusChip(
                          label: 'Health',
                          value: runtime.health.name,
                        ),
                        _StatusChip(
                          label: 'Peers',
                          value: runtime.discoveredPeers.toString(),
                        ),
                        _StatusChip(
                          label: 'Pending Bundles',
                          value: runtime.pendingBundles.toString(),
                        ),
                        _StatusChip(
                          label: 'Gateway',
                          value: runtime.gatewayEnabled
                              ? 'Enabled'
                              : 'Disabled',
                        ),
                        _StatusChip(
                          label: 'ACK Duplicates',
                          value: duplicateAckCount.toString(),
                        ),
                        _StatusChip(
                          label: 'TX ok/fail',
                          value:
                              '${runtime.telemetry.outboundSendSuccesses}/${runtime.telemetry.outboundSendFailures}',
                        ),
                        _StatusChip(
                          label: 'Relayed',
                          value: runtime.telemetry.inboundBundlesRelayed
                              .toString(),
                        ),
                        _StatusChip(
                          label: 'Stale Removed',
                          value: runtime.telemetry.stalePeerRemovals.toString(),
                        ),
                      ],
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
                      'Transport and Errors',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transport: '
                      '${runtime.health.name == 'idle' ? 'stopped' : 'running'} '
                      '• Health: ${runtime.health.name} '
                      '• Attempts: ${runtime.telemetry.outboundSendAttempts}',
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<List<AppErrorLogEntry>>(
                      valueListenable: errorLogStore.entries,
                      builder: (context, entries, _) {
                        if (entries.isEmpty) {
                          return const Text('No recent runtime errors.');
                        }
                        return Column(
                          children: entries.reversed
                              .take(3)
                              .map<Widget>(
                                (entry) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(entry.source),
                                  subtitle: Text(
                                    '${entry.timestamp.toIso8601String()}\n${entry.error}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ACK History',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (duplicateAckCount > 0) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        'Duplicate ACK activity detected: '
                        '$duplicateAckCount duplicate receipts '
                        'across $duplicateAckBundles ACK bundles.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Filter by ackFor, ackId, or source node',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _ackFilter = value.trim().toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: _duplicatesOnly,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show duplicate ACKs only'),
                      dense: true,
                      onChanged: (value) {
                        setState(() {
                          _duplicatesOnly = value;
                        });
                      },
                    ),
                    const SizedBox(height: 4),
                    ackEventsAsync.when(
                      loading: () => const Text('Loading ACK history...'),
                      error: (error, stackTrace) =>
                          Text('ACK history error: $error'),
                      data: (List<AckAuditEvent> ackEvents) {
                        final filteredEvents = ackEvents
                            .where((event) {
                              if (_duplicatesOnly &&
                                  event.duplicateCount == 0) {
                                return false;
                              }
                              if (_ackFilter.isEmpty) {
                                return true;
                              }
                              final haystack =
                                  '${event.ackForBundleId ?? ''} ${event.ackBundleId} ${event.sourceNodeId}'
                                      .toLowerCase();
                              return haystack.contains(_ackFilter);
                            })
                            .toList(growable: false);

                        if (filteredEvents.isEmpty) {
                          return const Text('No ACK events recorded yet.');
                        }
                        return Column(
                          children: filteredEvents
                              .take(8)
                              .map<Widget>(
                                (AckAuditEvent event) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'ackFor: ${event.ackForBundleId ?? '(unknown)'}',
                                  ),
                                  subtitle: Text(
                                    'ackId: ${event.ackBundleId}\n'
                                    'source: ${event.sourceNodeId} • '
                                    'receipts: ${event.totalReceipts} '
                                    '(duplicates: ${event.duplicateCount})\n'
                                    'last: ${event.lastReceivedAt.toIso8601String()}',
                                  ),
                                  isThreeLine: true,
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
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Sync History',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    syncJobsAsync.when(
                      loading: () => const Text('Loading sync history...'),
                      error: (error, stackTrace) =>
                          Text('History error: $error'),
                      data: (List<SyncJobHistoryEntry> jobs) {
                        if (jobs.isEmpty) {
                          return const Text('No sync runs recorded yet.');
                        }
                        return Column(
                          children: jobs
                              .take(5)
                              .map<Widget>(
                                (job) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '${job.success ? 'success' : 'failed'} • '
                                    'up:${job.uploadedCount} down:${job.downloadedCount}',
                                  ),
                                  subtitle: Text(
                                    '${job.completedAt.toIso8601String()} '
                                    '${job.mockMode ? '(mock)' : ''}'
                                    '${job.errorMessage == null ? '' : '\n${job.errorMessage}'}',
                                  ),
                                  isThreeLine: job.errorMessage != null,
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
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Gateway Sync',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
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
                      subtitle: const Text(
                        'When enabled, Sync Now can upload local pending events '
                        'and fetch confirmations/rejections plus remote updates.',
                      ),
                      onChanged: (value) =>
                          ref.read(gatewayEnabledProvider.notifier).state =
                              value,
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
                        error: (error, stackTrace) =>
                            Text('Sync failed: $error'),
                        data: (result) => Text(
                          'Uploaded: ${result.uploadedCount}, '
                          'Downloaded: ${result.downloadedCount} '
                          '${result.mockMode ? '(mock mode)' : ''}\n'
                          'Gateway: ${result.gatewayEnabled ? 'enabled' : 'disabled'}, '
                          'Internet: ${result.internetReachable ? 'reachable' : 'offline'}\n'
                          'At: ${result.completedAt.toIso8601String()}',
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
                      'Peer History',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    peerContactsAsync.when(
                      loading: () => const Text('Loading peers...'),
                      error: (error, stackTrace) => Text('Peer error: $error'),
                      data: (List<PeerContact> peers) {
                        if (peers.isEmpty) {
                          return const Text('No peers discovered yet.');
                        }
                        return Column(
                          children: peers
                              .take(5)
                              .map<Widget>(
                                (PeerContact peer) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(peer.nodeId),
                                  subtitle: Text(
                                    '${peer.host}:${peer.port} • '
                                    'seen ${peer.seenCount}x',
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
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'DTN Runtime',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Runtime uses NSD/mDNS discovery with LAN broadcast '
                      'fallback, plus TCP transport. Start runtime on two '
                      'devices in the same LAN/hotspot, then send chat '
                      'messages to test forwarding and ACK flow.',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton(
                          onPressed: () async {
                            final runtime = ref.read(nodeRuntimeProvider);
                            if (runtime.isRunning) {
                              await runtime.stop();
                            } else {
                              await runtime.start();
                            }
                          },
                          child: Text(
                            runtime.health.name != 'idle'
                                ? 'Stop Runtime'
                                : 'Start Runtime',
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => context.push('/queue'),
                          child: const Text('Open Queue'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => context.push('/chat'),
                          child: const Text('Open Chat'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => context.push('/files'),
                          child: const Text('Open Files'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => context.push('/sync'),
                          child: const Text('Open Sync'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => context.push('/settings'),
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}
