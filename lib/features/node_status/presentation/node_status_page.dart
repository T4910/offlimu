import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offlimu/core/debug/runtime_models.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/peer_contact.dart';

class NodeStatusPage extends ConsumerWidget {
  const NodeStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gatewaySyncCoordinatorProvider);

    final runtimeAsync = ref.watch(nodeRuntimeStateProvider);
    final peerContactsAsync = ref.watch(peerContactsProvider);
    final syncState = ref.watch(syncRunStateProvider);
    final gatewayEnabled = ref.watch(gatewayEnabledProvider);
    final gatewaySyncStatus = ref.watch(gatewaySyncStatusProvider);
    final nodeRuntime = ref.read(nodeRuntimeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('OffLiMU')),
      body: runtimeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (runtime) => SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _WelcomeCard(
                runtime: runtime,
                onCopyNodeId: () =>
                    _copyNodeId(context, runtime.identity.nodeId),
              ),
              const SizedBox(height: 10),
              _PeerHistoryCard(
                peersAsync: peerContactsAsync,
                onRefreshPeers: () async {
                  try {
                    await nodeRuntime.refreshPeersNow();
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Refresh failed: $error')),
                    );
                  }
                },
                onCopyPeer: (nodeId) => _copyNodeId(context, nodeId),
              ),
              const SizedBox(height: 10),
              const _QuickActionsCard(),
              const SizedBox(height: 10),
              _GatewaySyncCard(
                gatewayEnabled: gatewayEnabled,
                gatewaySyncStatus: gatewaySyncStatus,
                syncState: syncState,
                onSyncNow: () => ref
                    .read(gatewaySyncCoordinatorProvider)
                    .runManual(gatewayEnabled: gatewayEnabled),
                onGatewayChanged: (value) =>
                    ref.read(gatewayEnabledProvider.notifier).state = value,
              ),
              const SizedBox(height: 10),
              _RuntimeCard(
                isRunning: nodeRuntime.isRunning,
                health: runtime.health,
                onToggleRuntime: () async {
                  if (nodeRuntime.isRunning) {
                    await nodeRuntime.stop();
                  } else {
                    await nodeRuntime.start();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyNodeId(BuildContext context, String nodeId) async {
    await Clipboard.setData(ClipboardData(text: nodeId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Node ID copied')));
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.runtime, required this.onCopyNodeId});

  final NodeRuntimeState runtime;
  final VoidCallback onCopyNodeId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome to OffLiMU',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              runtime.identity.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: SelectableText(
                        'Node ID: ${runtime.identity.nodeId}',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy node ID',
                      visualDensity: VisualDensity.compact,
                      onPressed: onCopyNodeId,
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _StatusChip(label: 'Health', value: runtime.health.name),
                _StatusChip(
                  label: 'Nearby Peers',
                  value: runtime.discoveredPeers.toString(),
                ),
                _StatusChip(
                  label: 'Pending Bundles',
                  value: runtime.pendingBundles.toString(),
                ),
                _StatusChip(
                  label: 'Gateway',
                  value: runtime.gatewayEnabled ? 'Enabled' : 'Disabled',
                ),
                _StatusChip(
                  label: 'Relayed',
                  value: runtime.telemetry.inboundBundlesRelayed.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'What would you like to do?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  onPressed: () => context.push('/chat'),
                  filled: true,
                ),
                _ActionButton(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet',
                  onPressed: () => context.push('/wallet'),
                  filled: true,
                ),
                _ActionButton(
                  icon: Icons.travel_explore_rounded,
                  label: 'Web Search',
                  onPressed: () => context.push('/search'),
                  filled: true,
                ),
                _ActionButton(
                  icon: Icons.folder_rounded,
                  label: 'Files',
                  onPressed: () => context.push('/files'),
                  filled: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _ActionButton(
                  icon: Icons.storefront_rounded,
                  label: 'Commerce',
                  onPressed: () => context.push('/commerce'),
                ),
                _ActionButton(
                  icon: Icons.outbox_rounded,
                  label: 'Queue',
                  onPressed: () => context.push('/queue'),
                ),
                _ActionButton(
                  icon: Icons.sync_rounded,
                  label: 'Sync',
                  onPressed: () => context.push('/sync'),
                ),
                _ActionButton(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onPressed: () => context.push('/settings'),
                ),
                _ActionButton(
                  icon: Icons.bug_report_rounded,
                  label: 'Debugger',
                  onPressed: () => context.push('/debug'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeerHistoryCard extends StatelessWidget {
  const _PeerHistoryCard({
    required this.peersAsync,
    required this.onRefreshPeers,
    required this.onCopyPeer,
  });

  final AsyncValue<List<PeerContact>> peersAsync;
  final Future<void> Function() onRefreshPeers;
  final ValueChanged<String> onCopyPeer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Peer History',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh peers',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRefreshPeers,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            peersAsync.when(
              loading: () => const Text('Loading peers...'),
              error: (error, stackTrace) => Text('Peer error: $error'),
              data: (List<PeerContact> peers) {
                if (peers.isEmpty) {
                  return const Text(
                    'No peers yet. Start another OffLiMU node on this network.',
                  );
                }

                final sorted = peers.toList(growable: false)
                  ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
                return Column(
                  children: sorted
                      .take(8)
                      .map<Widget>(
                        (peer) => _PeerTile(
                          peer: peer,
                          onCopy: () => onCopyPeer(peer.nodeId),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  const _PeerTile({required this.peer, required this.onCopy});

  final PeerContact peer;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active = now.difference(peer.lastSeen).inSeconds <= 60;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Row(
            children: <Widget>[
              Expanded(child: Text(_shortNodeId(peer.nodeId))),
              _PeerBadge(active: active),
            ],
          ),
          subtitle: Text(
            '${peer.host}:${peer.port} • seen ${peer.seenCount}x\n'
            'Last connected ${_relativeTime(peer.lastSeen, now)}',
          ),
          isThreeLine: true,
          trailing: IconButton(
            tooltip: 'Copy peer node ID',
            visualDensity: VisualDensity.compact,
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
          ),
        ),
      ),
    );
  }
}

class _GatewaySyncCard extends StatelessWidget {
  const _GatewaySyncCard({
    required this.gatewayEnabled,
    required this.gatewaySyncStatus,
    required this.syncState,
    required this.onSyncNow,
    required this.onGatewayChanged,
  });

  final bool gatewayEnabled;
  final GatewaySyncCoordinatorStatus gatewaySyncStatus;
  final AsyncValue<SyncRunResult>? syncState;
  final Future<void> Function() onSyncNow;
  final ValueChanged<bool> onGatewayChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Gateway Sync', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onSyncNow,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sync Now'),
            ),
            SwitchListTile.adaptive(
              value: gatewayEnabled,
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Gateway Sync'),
              subtitle: Text(
                gatewaySyncStatus.deadLettered
                    ? 'Auto-sync is paused after repeated failures.'
                    : 'Share local updates and fetch server confirmations.',
              ),
              onChanged: onGatewayChanged,
            ),
            Text(
              'Auto-sync ${gatewaySyncStatus.enabled ? 'enabled' : 'disabled'} • '
              '${gatewaySyncStatus.deadLettered ? 'needs attention' : 'active'}'
              '${gatewaySyncStatus.nextDelaySeconds == null ? '' : ' • next attempt in ${gatewaySyncStatus.nextDelaySeconds}s'}',
            ),
            const SizedBox(height: 8),
            if (syncState == null)
              const Text('No sync run yet.')
            else
              syncState!.when(
                loading: () => const Text('Sync in progress...'),
                error: (error, stackTrace) => Text('Sync failed: $error'),
                data: (result) => Text(
                  'Uploaded ${result.uploadedCount}, downloaded ${result.downloadedCount} '
                  '${result.mockMode ? '(mock mode)' : ''}\n'
                  'Completed ${_formatDateTime(result.completedAt)}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuntimeCard extends StatelessWidget {
  const _RuntimeCard({
    required this.isRunning,
    required this.health,
    required this.onToggleRuntime,
  });

  final bool isRunning;
  final RuntimeHealth health;
  final Future<void> Function() onToggleRuntime;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Nearby Sharing',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              isRunning
                  ? 'Your node is listening for nearby OffLiMU devices.'
                  : 'Start the runtime to discover peers and exchange bundles.',
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onToggleRuntime,
              icon: Icon(
                isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(isRunning ? 'Stop Runtime' : 'Start Runtime'),
            ),
            const SizedBox(height: 8),
            Text('Current state: ${health.name}'),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _PeerBadge extends StatelessWidget {
  const _PeerBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(active ? 'Active' : 'Offline'),
      visualDensity: VisualDensity.compact,
      backgroundColor: active
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
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

String _shortNodeId(String nodeId) {
  if (nodeId.length <= 16) {
    return nodeId;
  }
  return '${nodeId.substring(0, 8)}...${nodeId.substring(nodeId.length - 5)}';
}

String _relativeTime(DateTime timestamp, DateTime now) {
  final difference = now.difference(timestamp);
  if (difference.inMinutes < 1) {
    return '< 1 min ago';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }
  return _formatDateTime(timestamp);
}

String _formatDateTime(DateTime timestamp) {
  final year = timestamp.year.toString().padLeft(4, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  final day = timestamp.day.toString().padLeft(2, '0');
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
