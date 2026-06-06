import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/bundle.dart';

class BundleExplorerPage extends ConsumerStatefulWidget {
  const BundleExplorerPage({super.key});

  @override
  ConsumerState<BundleExplorerPage> createState() => _BundleExplorerPageState();
}

class _BundleExplorerPageState extends ConsumerState<BundleExplorerPage> {
  String _filter = '';
  _BundleStatusFilter _statusFilter = _BundleStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final bundleRepository = ref.watch(bundleRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bundle Explorer')),
      body: StreamBuilder<List<Bundle>>(
        stream: bundleRepository.watchAllBundles(),
        builder: (context, snapshot) {
          final bundles = snapshot.data ?? const <Bundle>[];
          final filtered = _filterBundles(bundles);
          final counts = _bundleCounts(bundles);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'All bundles on device',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _MetricChip(
                            label: 'Total',
                            value: counts.total.toString(),
                          ),
                          _MetricChip(
                            label: 'Pending',
                            value: counts.pending.toString(),
                          ),
                          _MetricChip(
                            label: 'Sent',
                            value: counts.sent.toString(),
                          ),
                          _MetricChip(
                            label: 'Acked',
                            value: counts.acked.toString(),
                          ),
                          _MetricChip(
                            label: 'Failed',
                            value: counts.failed.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.search),
                          hintText:
                              'Filter by id, type, node, status, or payload ref',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _filter = value.trim().toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _BundleStatusFilter.values
                            .map(
                              (filter) => FilterChip(
                                label: Text(filter.label),
                                selected: _statusFilter == filter,
                                onSelected: (_) {
                                  setState(() {
                                    _statusFilter = filter;
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  snapshot.hasData == false)
                const Center(child: CircularProgressIndicator())
              else if (filtered.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No bundles match the current filters.'),
                  ),
                )
              else
                Column(
                  children: filtered
                      .map(
                        (bundle) => Card(
                          child: ListTile(
                            dense: true,
                            isThreeLine: true,
                            title: SelectableText(bundle.bundleId),
                            leading: Chip(
                              label: Text(bundle.type),
                              visualDensity: VisualDensity.compact,
                            ),
                            subtitle: SelectableText(
                              [
                                'from ${bundle.sourceNodeId} to ${bundle.destinationNodeId ?? '(broadcast)'}',
                                'status ${_bundleStatus(bundle)} • priority ${bundle.priority.name} • hop ${bundle.hopCount}',
                                'failedAttempts ${bundle.failedAttempts} • created ${bundle.createdAt.toIso8601String()}',
                                if (bundle.ackForBundleId != null)
                                  'ackFor ${bundle.ackForBundleId}',
                                if (bundle.payloadReference != null)
                                  'payloadRef ${bundle.payloadReference}',
                                if (bundle.lastError != null)
                                  'lastError ${bundle.lastError}',
                              ].join('\n'),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: <Widget>[
                                IconButton(
                                  tooltip: 'Resend bundle',
                                  icon: const Icon(Icons.refresh_rounded),
                                  onPressed: () async {
                                    final result = await ref
                                        .read(resendBundleUseCaseProvider)
                                        .resendBundle(bundle.bundleId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result.requeuedAny
                                                ? 'Bundle requeued.'
                                                : 'Bundle cannot be requeued.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                bundle.failedAttempts > 0 ||
                                        bundle.lastError != null
                                    ? const Icon(Icons.error_outline)
                                    : const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Bundle> _filterBundles(List<Bundle> bundles) {
    final visible = bundles
        .where((bundle) {
          if (_statusFilter != _BundleStatusFilter.all &&
              _bundleStatus(bundle) != _statusFilter.bundleStatus) {
            return false;
          }
          if (_filter.isEmpty) {
            return true;
          }

          final haystack =
              '${bundle.bundleId} ${bundle.type} ${bundle.sourceNodeId} ${bundle.destinationNodeId ?? ''} ${bundle.ackForBundleId ?? ''} ${bundle.payload ?? ''} ${bundle.payloadReference ?? ''} ${bundle.signature ?? ''} ${bundle.lastError ?? ''} ${bundle.createdAt.toIso8601String()}'
                  .toLowerCase();
          return haystack.contains(_filter);
        })
        .toList(growable: false);

    final sorted = visible.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  _BundleCounts _bundleCounts(List<Bundle> bundles) {
    return _BundleCounts(
      total: bundles.length,
      pending: bundles.where(_isPending).length,
      sent: bundles.where(_isSent).length,
      acked: bundles.where((bundle) => bundle.acknowledged).length,
      failed: bundles.where(_isFailed).length,
    );
  }

  String _bundleStatus(Bundle bundle) {
    if (_isFailed(bundle)) {
      return 'failed';
    }
    if (bundle.acknowledged) {
      return 'acked';
    }
    if (_isSent(bundle)) {
      return 'sent';
    }
    return 'pending';
  }

  bool _isPending(Bundle bundle) {
    return !_isFailed(bundle) && !bundle.acknowledged && bundle.sentAt == null;
  }

  bool _isSent(Bundle bundle) {
    return !bundle.acknowledged &&
        !(_isFailed(bundle)) &&
        bundle.sentAt != null;
  }

  bool _isFailed(Bundle bundle) {
    return bundle.failedAttempts > 0 || bundle.lastError != null;
  }
}

enum _BundleStatusFilter {
  all('All', 'all'),
  pending('Pending', 'pending'),
  sent('Sent', 'sent'),
  acked('Acked', 'acked'),
  failed('Failed', 'failed');

  const _BundleStatusFilter(this.label, this.bundleStatus);

  final String label;
  final String bundleStatus;
}

class _BundleCounts {
  const _BundleCounts({
    required this.total,
    required this.pending,
    required this.sent,
    required this.acked,
    required this.failed,
  });

  final int total;
  final int pending;
  final int sent;
  final int acked;
  final int failed;
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
