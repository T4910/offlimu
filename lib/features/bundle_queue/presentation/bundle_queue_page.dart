import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/bundle.dart';

class BundleQueuePage extends ConsumerWidget {
  const BundleQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundlesAsync = ref.watch(pendingBundlesProvider);
    final localIdentity = ref.watch(localNodeIdentityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Bundle Queue')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final now = DateTime.now();
          final bundle = Bundle(
            bundleId: 'bundle-${now.microsecondsSinceEpoch}',
            type: Bundle.typeChatMessage,
            sourceNodeId: localIdentity.nodeId,
            destinationNodeId: null,
            destinationScope: BundleDestinationScope.broadcast,
            priority: BundlePriority.normal,
            ackForBundleId: null,
            appId: 'offlimu.chat',
            createdAt: now,
            ttlSeconds: 3600,
          );
          await ref.read(bundleRepositoryProvider).save(bundle);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Demo bundle queued')));
          }
        },
        label: const Text('Enqueue Demo Bundle'),
        icon: const Icon(Icons.add_task),
      ),
      body: bundlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (bundles) {
          if (bundles.isEmpty) {
            return const Center(
              child: Text('No pending bundles. Add one to test persistence.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: bundles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final bundle = bundles[index];
              return Card(
                child: ListTile(
                  dense: true,
                  title: Text(bundle.type),
                  subtitle: Text(
                    '${bundle.bundleId}\n'
                    'Created: ${bundle.createdAt.toIso8601String()}\n'
                    'Dest: ${bundle.destinationNodeId ?? 'broadcast'}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Mark ACK',
                    icon: const Icon(Icons.done_outline),
                    onPressed: () async {
                      await ref
                          .read(bundleRepositoryProvider)
                          .markAcknowledged(bundle.bundleId);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
