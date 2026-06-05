import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/web_index_entry.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  bool _requesting = false;
  String? _status;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(
      _query.trim().isEmpty
          ? recentWebIndexEntriesProvider
          : webSearchEntriesProvider(_query),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Search')),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _SearchBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              children: <Widget>[
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'OffLiMU Search',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF214B2A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 22),
                _SearchBox(
                  controller: _controller,
                  enabled: !_requesting,
                  onSubmitted: _submit,
                ),
                if (_status != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _status!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4F6D54),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                entries.when(
                  data: (items) => _SearchResults(
                    entries: items,
                    query: _query,
                    onRequestFresh: _submit,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Text(
                    'Search index unavailable: $error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(String value) async {
    final query = value.trim();
    if (query.isEmpty || _requesting) {
      return;
    }

    setState(() {
      _query = query;
      _requesting = true;
      _status = 'Checking local cache...';
    });

    final repository = ref.read(webSearchRepositoryProvider);
    final localResults = await repository.search(query, limit: 1);
    if (localResults.isNotEmpty) {
      setState(() {
        _requesting = false;
        _status = 'Showing locally available results.';
      });
      return;
    }

    try {
      await ref
          .read(submitWebSearchRequestUseCaseProvider)
          .submit(
            localNodeId: ref.read(localNodeIdentityProvider).nodeId,
            query: query,
          );
      setState(() {
        _status = 'Search request broadcast. A gateway will fetch results.';
      });
    } catch (error) {
      setState(() {
        _status = 'Could not create search request: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _requesting = false);
      }
    }
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: TextField(
        controller: controller,
        enabled: enabled,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: 'Search cached pages or request the web',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            tooltip: 'Search',
            onPressed: enabled ? () => onSubmitted(controller.text) : null,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.92),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFFC9DEC4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFFC9DEC4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFF2F7A3A), width: 2),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.entries,
    required this.query,
    required this.onRequestFresh,
  });

  final List<WebIndexEntry> entries;
  final String query;
  final ValueChanged<String> onRequestFresh;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptySearchState(query: query, onRequestFresh: onRequestFresh);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: entries
          .map((entry) => _ResultTile(entry: entry))
          .toList(growable: false),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.entry});

  final WebIndexEntry entry;

  @override
  Widget build(BuildContext context) {
    final isComplete = entry.isComplete;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push(
            '/search/page/${Uri.encodeComponent(entry.contentHash)}',
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF214B2A),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    _AvailabilityBadge(isComplete: isComplete),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.url,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2F7A3A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  entry.snippet,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF536B58),
                  ),
                ),
                if (!isComplete) ...<Widget>[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: entry.expectedChunkCount <= 0
                        ? null
                        : (entry.receivedChunkCount / entry.expectedChunkCount)
                              .clamp(0, 1)
                              .toDouble(),
                    minHeight: 4,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.isComplete});

  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isComplete ? const Color(0xFFE8F5E4) : const Color(0xFFFFF3DE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isComplete ? const Color(0xFF8BBE82) : const Color(0xFFE1AF5B),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          isComplete ? 'Cached' : 'Partial',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isComplete
                ? const Color(0xFF24572B)
                : const Color(0xFF865B19),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query, required this.onRequestFresh});

  final String query;
  final ValueChanged<String> onRequestFresh;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    return Center(
      child: Column(
        children: <Widget>[
          Icon(
            hasQuery ? Icons.travel_explore_rounded : Icons.public_rounded,
            size: 48,
            color: const Color(0xFF4F7C55),
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery
                ? 'No local page matches "$query".'
                : 'No cached pages yet.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF214B2A),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasQuery) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => onRequestFresh(query),
              icon: const Icon(Icons.wifi_tethering_rounded),
              label: const Text('Broadcast Search Request'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchBackground extends StatelessWidget {
  const _SearchBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFF7FCF4), Color(0xFFEAF5E7)],
        ),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCEAD8).withValues(alpha: 0.34)
      ..strokeWidth = 1;
    const spacing = 12.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
