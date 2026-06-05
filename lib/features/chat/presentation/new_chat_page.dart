import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/peer_contact.dart';

class NewChatPage extends ConsumerStatefulWidget {
  const NewChatPage({super.key});

  @override
  ConsumerState<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends ConsumerState<NewChatPage> {
  final TextEditingController _manualNodeIdController = TextEditingController();

  @override
  void dispose() {
    _manualNodeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localNodeId = ref.watch(localNodeIdentityProvider).nodeId;
    final peersAsync = ref.watch(peerContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          TextField(
            controller: _manualNodeIdController,
            textInputAction: TextInputAction.go,
            decoration: const InputDecoration(
              labelText: 'Manual node ID',
              hintText: 'Enter destination node ID',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            onSubmitted: (_) => _openManualChat(localNodeId),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _openManualChat(localNodeId),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Open chat'),
            ),
          ),
          const SizedBox(height: 20),
          Text('Peer history', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          peersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Error: $error'),
            data: (peers) {
              final options = peers
                  .where((peer) => peer.nodeId != localNodeId)
                  .toList(growable: false);
              if (options.isEmpty) {
                return const Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.history),
                    title: Text('No peers discovered yet'),
                    subtitle: Text('Enter a node ID manually to start.'),
                  ),
                );
              }

              return Column(
                children: options
                    .map(
                      (peer) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PeerTile(
                          peer: peer,
                          onTap: () => _openPeerChat(peer.nodeId),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openManualChat(String localNodeId) {
    final nodeId = _manualNodeIdController.text.trim();
    if (nodeId.isEmpty || nodeId == localNodeId) {
      return;
    }
    _openPeerChat(nodeId);
  }

  void _openPeerChat(String peerNodeId) {
    context.push('/chat/${Uri.encodeComponent(peerNodeId)}');
  }
}

class _PeerTile extends StatelessWidget {
  const _PeerTile({required this.peer, required this.onTap});

  final PeerContact peer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(child: Text(_initialFor(peer.nodeId))),
        title: Text(peer.nodeId, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${peer.host}:${peer.port}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _initialFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.characters.first.toUpperCase();
  }
}
