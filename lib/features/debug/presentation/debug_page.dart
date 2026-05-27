import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/debug/runtime_log_store.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/core/error/app_error_log_store.dart';
import 'package:offlimu/domain/entities/ack_event.dart';
import 'package:offlimu/domain/entities/bundle.dart';
import 'package:offlimu/domain/entities/chat_message.dart'
  show ChatMessage, MessageDeliveryStatus;
import 'package:offlimu/domain/entities/content_metadata_record.dart';
import 'package:offlimu/domain/entities/peer_contact.dart';
import 'package:offlimu/domain/entities/sync_job_history_entry.dart';
import 'package:offlimu/node_runtime/gateway_sync_coordinator.dart';
import 'package:offlimu/node_runtime/node_runtime_state.dart';
import 'package:offlimu/node_runtime/sync_engine.dart';

class DebugPage extends ConsumerStatefulWidget {
  const DebugPage({super.key});

  @override
  ConsumerState<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends ConsumerState<DebugPage> {
  String _filter = '';
  bool _failuresOnly = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(gatewaySyncCoordinatorProvider);

    final runtimeAsync = ref.watch(nodeRuntimeStateProvider);
    final runtime = ref.watch(nodeRuntimeProvider);
    final peerContactsAsync = ref.watch(peerContactsProvider);
    final pendingBundlesAsync = ref.watch(pendingBundlesProvider);
    final chatMessagesAsync = ref.watch(chatMessagesProvider);
    final ackEventsAsync = ref.watch(recentAckEventsProvider);
    final syncJobsAsync = ref.watch(recentSyncJobsProvider);
    final contentMetadataAsync = ref.watch(recentContentMetadataProvider);
    final syncState = ref.watch(syncRunStateProvider);
    final gatewayEnabled = ref.watch(gatewayEnabledProvider);
    final gatewayStatus = ref.watch(gatewaySyncStatusProvider);
    final errorLogStore = ref.watch(appErrorLogStoreProvider);
    final runtimeLogStore = ref.watch(runtimeLogStoreProvider);
    final bundleRepository = ref.watch(bundleRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OffLiMU Debug Console'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Copy diagnostics',
            onPressed: runtimeAsync.hasValue
                ? () async {
                    await _copyDiagnostics(
                      context: context,
                      runtimeState: runtimeAsync.requireValue,
                      peers: peerContactsAsync.valueOrNull ?? const <PeerContact>[],
                      pendingBundles:
                          pendingBundlesAsync.valueOrNull ?? const <Bundle>[],
                      chatMessages:
                          chatMessagesAsync.valueOrNull ?? const <ChatMessage>[],
                      ackEvents:
                          ackEventsAsync.valueOrNull ?? const <AckAuditEvent>[],
                      syncJobs:
                          syncJobsAsync.valueOrNull ?? const <SyncJobHistoryEntry>[],
                      contentMetadata: contentMetadataAsync.valueOrNull ??
                          const <ContentMetadataRecord>[],
                      errorEntries: errorLogStore.entries.value,
                      runtimeLogs: runtimeLogStore.entries.value,
                      syncState: syncState?.valueOrNull,
                      gatewayEnabled: gatewayEnabled,
                      gatewayStatus: gatewayStatus,
                    );
                  }
                : null,
            icon: const Icon(Icons.copy_all_outlined),
          ),
        ],
      ),
      body: runtimeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (runtimeState) => ListView(
          padding: const EdgeInsets.all(12),
          children: <Widget>[
            _SectionCard(
              title: 'Runtime Overview',
              subtitle: 'Landing zone for transport, bundle, ACK, and sync debugging.',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton(
                    onPressed: runtime.isRunning
                        ? () => _runAction(context, runtime.stop)
                        : () => _runAction(context, runtime.start),
                    child: Text(runtime.isRunning ? 'Stop Runtime' : 'Start Runtime'),
                  ),
                  OutlinedButton(
                    onPressed: () => _runAction(context, runtime.flushPendingNow),
                    child: const Text('Flush Pending'),
                  ),
                  OutlinedButton(
                    onPressed: () => _runAction(context, runtime.refreshPeersNow),
                    child: const Text('Refresh Peers'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _filter = '';
                        _failuresOnly = false;
                      });
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    runtimeState.identity.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  SelectableText('Node ID: ${runtimeState.identity.nodeId}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _MetricChip(label: 'Health', value: runtimeState.health.name),
                      _MetricChip(
                        label: 'Peers',
                        value: runtimeState.discoveredPeers.toString(),
                      ),
                      _MetricChip(
                        label: 'Pending',
                        value: runtimeState.pendingBundles.toString(),
                      ),
                      _MetricChip(
                        label: 'Gateway',
                        value: runtimeState.gatewayEnabled ? 'Enabled' : 'Disabled',
                      ),
                      _MetricChip(
                        label: 'TX ok/fail',
                        value:
                            '${runtimeState.telemetry.outboundSendSuccesses}/${runtimeState.telemetry.outboundSendFailures}',
                      ),
                      _MetricChip(
                        label: 'Ingested',
                        value: runtimeState.telemetry.inboundBundlesReceived.toString(),
                      ),
                      _MetricChip(
                        label: 'Relayed',
                        value: runtimeState.telemetry.inboundBundlesRelayed.toString(),
                      ),
                      _MetricChip(
                        label: 'ACKs in',
                        value: runtimeState.telemetry.inboundAcksReceived.toString(),
                      ),
                      _MetricChip(
                        label: 'ACKs out',
                        value: runtimeState.telemetry.outboundAcksGenerated.toString(),
                      ),
                      _MetricChip(
                        label: 'Liveness fails',
                        value: runtimeState.telemetry.livenessFailures.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Filter bundles, peers, ACKs, messages, logs',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _filter = value.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _failuresOnly,
                    title: const Text('Show failures only'),
                    onChanged: (value) {
                      setState(() {
                        _failuresOnly = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Receiver Ingest',
              subtitle: 'What the receiver actually saved into chat and ACK history.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _LabelValueRow(
                    label: 'Chat projection',
                    value: runtimeState.telemetry.inboundBundlesReceived.toString(),
                  ),
                  const SizedBox(height: 8),
                  chatMessagesAsync.when(
                    loading: () => const Text('Loading chat projections...'),
                    error: (error, stackTrace) => Text('Chat error: $error'),
                    data: (messages) {
                      final visible = _filterChatMessages(messages);
                      if (visible.isEmpty) {
                        return const Text('No chat messages recorded yet.');
                      }
                      return Column(
                        children: visible
                            .map(
                              (message) => _EntityTile(
                                title: message.messageId,
                                leadingLabel: message.deliveryStatus.name,
                                subtitleLines: <String>[
                                  'from ${message.sourceNodeId} to ${message.destinationNodeId ?? '(broadcast)'}',
                                  message.body,
                                  'created ${message.createdAt.toIso8601String()} • outgoing ${message.isOutgoing}',
                                  'failedAttempts ${message.failedAttempts}${message.lastError == null ? '' : ' • ${message.lastError}'}',
                                ],
                                highlight: _isFailureMessage(message),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ackEventsAsync.when(
                    loading: () => const Text('Loading ACK history...'),
                    error: (error, stackTrace) => Text('ACK error: $error'),
                    data: (ackEvents) {
                      final visible = _filterAckEvents(ackEvents);
                      if (visible.isEmpty) {
                        return const Text('No ACK events recorded yet.');
                      }
                      return Column(
                        children: visible
                            .map(
                              (event) => _EntityTile(
                                title: event.ackBundleId,
                                leadingLabel: event.duplicateCount > 0
                                    ? 'duplicate'
                                    : 'ack',
                                subtitleLines: <String>[
                                  'ackFor ${event.ackForBundleId ?? '(unknown)'}',
                                  'source ${event.sourceNodeId}',
                                  'receipts ${event.totalReceipts} • duplicates ${event.duplicateCount}',
                                  'first ${event.firstReceivedAt.toIso8601String()}',
                                  'last ${event.lastReceivedAt.toIso8601String()}',
                                ],
                                highlight: event.duplicateCount > 0,
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Transport and Logs',
              subtitle: 'Socket attempts, runtime events, and captured errors.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Transport attempts: ${runtimeState.telemetry.outboundSendAttempts}  •  '
                    'Successes: ${runtimeState.telemetry.outboundSendSuccesses}  •  '
                    'Failures: ${runtimeState.telemetry.outboundSendFailures}',
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<List<RuntimeLogEntry>>(
                    valueListenable: runtimeLogStore.entries,
                    builder: (context, entries, _) {
                      final visible = _filterRuntimeLogs(entries);
                      if (visible.isEmpty) {
                        return const Text('No runtime log entries recorded yet.');
                      }
                      return Column(
                        children: visible
                            .map(
                              (entry) => _EntityTile(
                                title: '${entry.level} • ${entry.message}',
                                leadingLabel: entry.scope,
                                subtitleLines: <String>[
                                  entry.timestamp.toIso8601String(),
                                  if (entry.fields.isNotEmpty)
                                    'fields: ${_formatFields(entry.fields)}',
                                  if (entry.error != null) 'error: ${entry.error}',
                                  if (entry.stackTrace != null)
                                    'stack: ${entry.stackTrace}',
                                ],
                                highlight: entry.level == 'ERROR',
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<List<AppErrorLogEntry>>(
                    valueListenable: errorLogStore.entries,
                    builder: (context, entries, _) {
                      final visible = _filterErrorEntries(entries);
                      if (visible.isEmpty) {
                        return const Text('No recent app errors recorded.');
                      }
                      return Column(
                        children: visible
                            .map(
                              (entry) => _EntityTile(
                                title: entry.source,
                                leadingLabel: 'error',
                                subtitleLines: <String>[
                                  entry.timestamp.toIso8601String(),
                                  entry.error,
                                  entry.stackTrace,
                                ],
                                highlight: true,
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Peers and Discovery',
              subtitle: 'Persisted peers, discovery hits, and the next-hop map.',
              child: peerContactsAsync.when(
                loading: () => const Text('Loading peers...'),
                error: (error, stackTrace) => Text('Peer error: $error'),
                data: (peers) {
                  final visible = _filterPeers(peers);
                  if (visible.isEmpty) {
                    return const Text('No peers discovered yet.');
                  }
                  return Column(
                    children: visible
                        .map(
                          (peer) => _EntityTile(
                            title: peer.nodeId,
                            leadingLabel: '${peer.host}:${peer.port}',
                            subtitleLines: <String>[
                              'lastSeen ${peer.lastSeen.toIso8601String()}',
                              'seenCount ${peer.seenCount}',
                            ],
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Bundle Timeline',
              subtitle: 'Pending and typed bundle history, including relay and rejection states.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  pendingBundlesAsync.when(
                    loading: () => const Text('Loading pending bundles...'),
                    error: (error, stackTrace) => Text('Pending error: $error'),
                    data: (bundles) => _buildBundleList(
                      context,
                      'Pending bundles',
                      _filterBundles(bundles),
                      emptyText: 'No pending bundles.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Bundle>>(
                    stream: bundleRepository.watchBundlesByType(Bundle.typeChatMessage),
                    builder: (context, snapshot) => _buildBundleList(
                      context,
                      'Chat bundles',
                      _filterBundles(snapshot.data ?? const <Bundle>[]),
                      loading: !snapshot.hasData && !snapshot.hasError,
                      emptyText: 'No chat bundles recorded yet.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Bundle>>(
                    stream: bundleRepository.watchBundlesByType(Bundle.typeAck),
                    builder: (context, snapshot) => _buildBundleList(
                      context,
                      'ACK bundles',
                      _filterBundles(snapshot.data ?? const <Bundle>[]),
                      loading: !snapshot.hasData && !snapshot.hasError,
                      emptyText: 'No ACK bundles recorded yet.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Bundle>>(
                    stream:
                        bundleRepository.watchBundlesByType(Bundle.typeSyncRejection),
                    builder: (context, snapshot) => _buildBundleList(
                      context,
                      'Sync rejection bundles',
                      _filterBundles(snapshot.data ?? const <Bundle>[]),
                      loading: !snapshot.hasData && !snapshot.hasError,
                      emptyText: 'No sync rejection bundles recorded yet.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Bundle>>(
                    stream: bundleRepository.watchBundlesByType(Bundle.typeFileShareMetadata),
                    builder: (context, snapshot) => _buildBundleList(
                      context,
                      'File metadata bundles',
                      _filterBundles(snapshot.data ?? const <Bundle>[]),
                      loading: !snapshot.hasData && !snapshot.hasError,
                      emptyText: 'No file metadata bundles recorded yet.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Bundle>>(
                    stream: bundleRepository.watchBundlesByType(Bundle.typeFileShareChunk),
                    builder: (context, snapshot) => _buildBundleList(
                      context,
                      'File chunk bundles',
                      _filterBundles(snapshot.data ?? const <Bundle>[]),
                      loading: !snapshot.hasData && !snapshot.hasError,
                      emptyText: 'No file chunk bundles recorded yet.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Chat Projections',
              subtitle: 'What the UI will actually render after ingest.',
              child: chatMessagesAsync.when(
                loading: () => const Text('Loading chat messages...'),
                error: (error, stackTrace) => Text('Chat error: $error'),
                data: (messages) {
                  final visible = _filterChatMessages(messages);
                  if (visible.isEmpty) {
                    return const Text('No chat projection rows yet.');
                  }
                  return Column(
                    children: visible
                        .map(
                          (message) => _EntityTile(
                            title: message.messageId,
                            leadingLabel: message.deliveryStatus.name,
                            subtitleLines: <String>[
                              'from ${message.sourceNodeId} to ${message.destinationNodeId ?? '(broadcast)'}',
                              message.body,
                            ],
                            highlight: message.deliveryStatus == MessageDeliveryStatus.failed,
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Files and Content',
              subtitle: 'Stored content metadata and chunk assembly hints.',
              child: contentMetadataAsync.when(
                loading: () => const Text('Loading content metadata...'),
                error: (error, stackTrace) => Text('Content error: $error'),
                data: (content) {
                  final visible = _filterContent(content);
                  if (visible.isEmpty) {
                    return const Text('No content metadata recorded yet.');
                  }
                  return Column(
                    children: visible
                        .map(
                          (record) => _EntityTile(
                            title: record.contentHash,
                            leadingLabel: record.mimeType ?? 'unknown',
                            subtitleLines: <String>[
                              'bytes ${record.totalBytes} • chunks ${record.chunkCount}',
                              'created ${record.createdAt.toIso8601String()}',
                              if (record.localPath != null) 'path ${record.localPath}',
                            ],
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Sync and Gateway',
              subtitle: 'Manual sync state, gateway status, and recent job history.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Gateway: ${gatewayEnabled ? 'enabled' : 'disabled'} • '
                    'auto-sync ${gatewayStatus.enabled ? 'enabled' : 'disabled'} • '
                    'failures ${gatewayStatus.consecutiveFailures} • '
                    '${gatewayStatus.deadLettered ? 'dead-lettered' : 'active'}'
                    '${gatewayStatus.nextDelaySeconds == null ? '' : ' • retry in ${gatewayStatus.nextDelaySeconds}s'}',
                  ),
                  const SizedBox(height: 8),
                  if (syncState == null)
                    const Text('No sync run yet.')
                  else
                    syncState.when(
                      loading: () => const Text('Sync in progress...'),
                      error: (error, stackTrace) => Text('Sync error: $error'),
                      data: (result) => Text(
                        'Uploaded ${result.uploadedCount}, downloaded ${result.downloadedCount} • '
                        '${result.mockMode ? 'mock' : 'live'} • '
                        '${result.gatewayEnabled ? 'gateway on' : 'gateway off'} • '
                        '${result.internetReachable ? 'online' : 'offline'} • '
                        '${result.completedAt.toIso8601String()}',
                      ),
                    ),
                  const SizedBox(height: 12),
                  syncJobsAsync.when(
                    loading: () => const Text('Loading sync jobs...'),
                    error: (error, stackTrace) => Text('Sync jobs error: $error'),
                    data: (jobs) {
                      final visible = _filterSyncJobs(jobs);
                      if (visible.isEmpty) {
                        return const Text('No sync jobs recorded yet.');
                      }
                      return Column(
                        children: visible
                            .map(
                              (job) => _EntityTile(
                                title: job.success ? 'success' : 'failed',
                                leadingLabel: job.mockMode ? 'mock' : 'live',
                                subtitleLines: <String>[
                                  'uploaded ${job.uploadedCount} • downloaded ${job.downloadedCount}',
                                  'started ${job.startedAt.toIso8601String()}',
                                  'completed ${job.completedAt.toIso8601String()}',
                                  'gateway ${job.gatewayEnabled ? 'enabled' : 'disabled'} • internet ${job.internetReachable ? 'reachable' : 'offline'}',
                                  if (job.errorMessage != null) 'error ${job.errorMessage}',
                                ],
                                highlight: !job.success,
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $error')),
      );
    }
  }

  Future<void> _copyDiagnostics({
    required BuildContext context,
    required NodeRuntimeState runtimeState,
    required List<PeerContact> peers,
    required List<Bundle> pendingBundles,
    required List<ChatMessage> chatMessages,
    required List<AckAuditEvent> ackEvents,
    required List<SyncJobHistoryEntry> syncJobs,
    required List<ContentMetadataRecord> contentMetadata,
    required List<AppErrorLogEntry> errorEntries,
    required List<RuntimeLogEntry> runtimeLogs,
    required SyncRunResult? syncState,
    required bool gatewayEnabled,
    required GatewaySyncCoordinatorStatus gatewayStatus,
  }) async {
    final buffer = StringBuffer()
      ..writeln('OffLiMU Debug Diagnostics')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Node: ${runtimeState.identity.displayName} (${runtimeState.identity.nodeId})')
      ..writeln('Health: ${runtimeState.health.name}')
      ..writeln('Peers: ${runtimeState.discoveredPeers}')
      ..writeln('Pending bundles: ${runtimeState.pendingBundles}')
      ..writeln('Gateway enabled: $gatewayEnabled')
      ..writeln('Gateway status: enabled=${gatewayStatus.enabled}, failures=${gatewayStatus.consecutiveFailures}, deadLettered=${gatewayStatus.deadLettered}, nextDelay=${gatewayStatus.nextDelaySeconds}')
      ..writeln('Telemetry: ${jsonEncode(_telemetryToJson(runtimeState.telemetry))}')
      ..writeln()
      ..writeln('Peers (${peers.length})')
      ..writeln(peers.map(_peerToLine).join('\n'))
      ..writeln()
      ..writeln('Pending bundles (${pendingBundles.length})')
      ..writeln(pendingBundles.map(_bundleToLine).join('\n'))
      ..writeln()
      ..writeln('Chat messages (${chatMessages.length})')
      ..writeln(chatMessages.map(_chatMessageToLine).join('\n'))
      ..writeln()
      ..writeln('ACK events (${ackEvents.length})')
      ..writeln(ackEvents.map(_ackEventToLine).join('\n'))
      ..writeln()
      ..writeln('Sync jobs (${syncJobs.length})')
      ..writeln(syncJobs.map(_syncJobToLine).join('\n'))
      ..writeln()
      ..writeln('Content metadata (${contentMetadata.length})')
      ..writeln(contentMetadata.map(_contentToLine).join('\n'))
      ..writeln()
      ..writeln('Runtime logs (${runtimeLogs.length})')
      ..writeln(runtimeLogs.map(_runtimeLogToLine).join('\n'))
      ..writeln()
      ..writeln('App errors (${errorEntries.length})')
      ..writeln(errorEntries.map(_appErrorToLine).join('\n'));

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics copied to clipboard')),
    );
  }

  List<PeerContact> _filterPeers(List<PeerContact> peers) {
    final visible = peers.where((peer) {
      if (_filter.isEmpty) {
        return !_failuresOnly;
      }
      final haystack =
          '${peer.nodeId} ${peer.host} ${peer.port} ${peer.lastSeen.toIso8601String()} ${peer.seenCount}'
              .toLowerCase();
      return haystack.contains(_filter);
    }).toList(growable: false);

    final sorted = visible.toList(growable: false)
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    return sorted;
  }

  List<Bundle> _filterBundles(List<Bundle> bundles) {
    final visible = bundles.where((bundle) {
      if (_failuresOnly && !_isFailureBundle(bundle)) {
        return false;
      }
      if (_filter.isEmpty) {
        return true;
      }
      final haystack =
          '${bundle.bundleId} ${bundle.type} ${bundle.sourceNodeId} ${bundle.destinationNodeId ?? ''} ${bundle.ackForBundleId ?? ''} ${bundle.payloadReference ?? ''} ${bundle.hopCount} ${bundle.failedAttempts} ${bundle.lastError ?? ''} ${bundle.sentAt?.toIso8601String() ?? ''}'
              .toLowerCase();
      return haystack.contains(_filter);
    }).toList(growable: false);

    final sorted = visible.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<AckAuditEvent> _filterAckEvents(List<AckAuditEvent> ackEvents) {
    final visible = ackEvents.where((event) {
      if (_failuresOnly && event.duplicateCount == 0) {
        return false;
      }
      if (_filter.isEmpty) {
        return true;
      }
      final haystack =
          '${event.ackBundleId} ${event.ackForBundleId ?? ''} ${event.sourceNodeId} ${event.duplicateCount}'
              .toLowerCase();
      return haystack.contains(_filter);
    }).toList(growable: false);

    final sorted = visible.toList(growable: false)
      ..sort((a, b) => b.lastReceivedAt.compareTo(a.lastReceivedAt));
    return sorted;
  }

  List<ChatMessage> _filterChatMessages(List<ChatMessage> messages) {
    final visible = messages.where((message) {
      if (_failuresOnly && message.deliveryStatus == MessageDeliveryStatus.acked) {
        return false;
      }
      if (_filter.isEmpty) {
        return true;
      }
      final haystack =
          '${message.messageId} ${message.sourceNodeId} ${message.destinationNodeId ?? ''} ${message.body} ${message.deliveryStatus.name} ${message.lastError ?? ''}'
              .toLowerCase();
      return haystack.contains(_filter);
    }).toList(growable: false);

    final sorted = visible.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<ContentMetadataRecord> _filterContent(List<ContentMetadataRecord> content) {
    final visible = content.where((record) {
      if (_filter.isEmpty) {
        return true;
      }
      final haystack =
          '${record.contentHash} ${record.mimeType ?? ''} ${record.totalBytes} ${record.chunkCount} ${record.localPath ?? ''}'
              .toLowerCase();
      return haystack.contains(_filter);
    }).toList(growable: false);

    final sorted = visible.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<SyncJobHistoryEntry> _filterSyncJobs(List<SyncJobHistoryEntry> jobs) {
    final visible = jobs.where((job) {
      if (_failuresOnly && job.success) {
        return false;
      }
      if (_filter.isEmpty) {
        return true;
      }
      final haystack =
          '${job.id ?? ''} ${job.uploadedCount} ${job.downloadedCount} ${job.errorMessage ?? ''} ${job.completedAt.toIso8601String()}'
              .toLowerCase();
      return haystack.contains(_filter);
    }).toList(growable: false);

    final sorted = visible.toList(growable: false)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sorted;
  }

  List<RuntimeLogEntry> _filterRuntimeLogs(List<RuntimeLogEntry> entries) {
    final visible = entries.where((entry) {
      if (_failuresOnly && entry.level == 'INFO') {
        return false;
      }
      if (_filter.isEmpty) {
        return true;
      }
      final haystack =
          '${entry.level} ${entry.scope} ${entry.message} ${_formatFields(entry.fields)} ${entry.error ?? ''}'
              .toLowerCase();
      return haystack.contains(_filter);
    }).toList(growable: false);

    final sorted = visible.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  List<AppErrorLogEntry> _filterErrorEntries(List<AppErrorLogEntry> entries) {
    final visible = entries.where((entry) {
      if (_filter.isEmpty) {
        return true;
      }
      final haystack =
          '${entry.source} ${entry.error} ${entry.stackTrace} ${entry.timestamp.toIso8601String()}'
              .toLowerCase();
      return haystack.contains(_filter);
    }).toList(growable: false);

    final sorted = visible.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  bool _isFailureBundle(Bundle bundle) {
    return bundle.failedAttempts > 0 ||
        bundle.lastError != null ||
        (bundle.acknowledged && bundle.type == Bundle.typeSyncRejection);
  }

  bool _isFailureMessage(ChatMessage message) {
    return message.deliveryStatus == MessageDeliveryStatus.failed ||
        message.failedAttempts > 0 ||
        message.lastError != null;
  }

  Widget _buildBundleList(
    BuildContext context,
    String title,
    List<Bundle> bundles, {
    bool loading = false,
    required String emptyText,
  }) {
    final visible = bundles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (loading)
          const Text('Loading...')
        else if (visible.isEmpty)
          Text(emptyText)
        else
          Column(
            children: visible
                .take(6)
                .map(
                  (bundle) => _EntityTile(
                    title: bundle.bundleId,
                    leadingLabel: bundle.type,
                    subtitleLines: <String>[
                      'from ${bundle.sourceNodeId} to ${bundle.destinationNodeId ?? '(broadcast)'}',
                      'priority ${bundle.priority.name} • scope ${bundle.destinationScope.name} • hopCount ${bundle.hopCount}',
                      'status ${bundle.acknowledged ? 'acknowledged' : 'pending'} • failedAttempts ${bundle.failedAttempts}',
                      if (bundle.ackForBundleId != null) 'ackFor ${bundle.ackForBundleId}',
                      if (bundle.payloadReference != null) 'payloadRef ${bundle.payloadReference}',
                      if (bundle.lastError != null) 'lastError ${bundle.lastError}',
                    ],
                    highlight: bundle.failedAttempts > 0 || bundle.lastError != null,
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }

  String _peerToLine(PeerContact peer) {
    return '${peer.nodeId} @ ${peer.host}:${peer.port} lastSeen=${peer.lastSeen.toIso8601String()} seenCount=${peer.seenCount}';
  }

  String _bundleToLine(Bundle bundle) {
    return '${bundle.bundleId} type=${bundle.type} from=${bundle.sourceNodeId} to=${bundle.destinationNodeId ?? '(broadcast)'} hop=${bundle.hopCount} acked=${bundle.acknowledged} failedAttempts=${bundle.failedAttempts} lastError=${bundle.lastError ?? ''}';
  }

  String _chatMessageToLine(ChatMessage message) {
    return '${message.messageId} ${message.deliveryStatus.name} from=${message.sourceNodeId} to=${message.destinationNodeId ?? '(broadcast)'} body=${message.body} failedAttempts=${message.failedAttempts} lastError=${message.lastError ?? ''}';
  }

  String _ackEventToLine(AckAuditEvent event) {
    return '${event.ackBundleId} ackFor=${event.ackForBundleId ?? '(unknown)'} source=${event.sourceNodeId} receipts=${event.totalReceipts} duplicates=${event.duplicateCount}';
  }

  String _syncJobToLine(SyncJobHistoryEntry job) {
    return '${job.success ? 'success' : 'failed'} uploaded=${job.uploadedCount} downloaded=${job.downloadedCount} mock=${job.mockMode} gateway=${job.gatewayEnabled} internet=${job.internetReachable} error=${job.errorMessage ?? ''}';
  }

  String _contentToLine(ContentMetadataRecord record) {
    return '${record.contentHash} bytes=${record.totalBytes} chunks=${record.chunkCount} mime=${record.mimeType ?? ''} path=${record.localPath ?? ''}';
  }

  String _runtimeLogToLine(RuntimeLogEntry entry) {
    return '${entry.timestamp.toIso8601String()} ${entry.level} ${entry.scope} ${entry.message} ${_formatFields(entry.fields)} ${entry.error ?? ''}';
  }

  String _appErrorToLine(AppErrorLogEntry entry) {
    return '${entry.timestamp.toIso8601String()} ${entry.source} ${entry.error}';
  }

  Map<String, Object?> _telemetryToJson(RuntimeTelemetry telemetry) {
    return <String, Object?>{
      'discoveryEvents': telemetry.discoveryEvents,
      'peerUpserts': telemetry.peerUpserts,
      'duplicatePeerSuppressions': telemetry.duplicatePeerSuppressions,
      'stalePeerRemovals': telemetry.stalePeerRemovals,
      'livenessChecks': telemetry.livenessChecks,
      'livenessFailures': telemetry.livenessFailures,
      'outboundSendAttempts': telemetry.outboundSendAttempts,
      'outboundSendSuccesses': telemetry.outboundSendSuccesses,
      'outboundSendFailures': telemetry.outboundSendFailures,
      'inboundBundlesReceived': telemetry.inboundBundlesReceived,
      'inboundBundlesRelayed': telemetry.inboundBundlesRelayed,
      'inboundAcksReceived': telemetry.inboundAcksReceived,
      'outboundAcksGenerated': telemetry.outboundAcksGenerated,
    };
  }

  String _formatFields(Map<String, Object?> fields) {
    if (fields.isEmpty) {
      return '{}';
    }
    return fields.entries.map((entry) => '${entry.key}=${entry.value}').join(', ');
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: Theme.of(context).textTheme.titleSmall),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(subtitle!),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: trailing!,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

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

class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: SelectableText(value)),
      ],
    );
  }
}

class _EntityTile extends StatelessWidget {
  const _EntityTile({
    required this.title,
    required this.leadingLabel,
    required this.subtitleLines,
    this.highlight = false,
  });

  final String title;
  final String leadingLabel;
  final List<String> subtitleLines;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? Theme.of(context).colorScheme.errorContainer : null,
      child: ListTile(
        dense: true,
        isThreeLine: subtitleLines.length > 2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: SelectableText(title),
        leading: Chip(
          label: Text(leadingLabel),
          visualDensity: VisualDensity.compact,
        ),
        subtitle: SelectableText(subtitleLines.join('\n')),
      ),
    );
  }
}