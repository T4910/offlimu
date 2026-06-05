import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/web_index_entry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OfflineWebPage extends ConsumerWidget {
  const OfflineWebPage({super.key, required this.contentHash});

  final String contentHash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(webIndexEntryProvider(contentHash));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Page'),
        actions: <Widget>[
          entry.when(
            data: (value) => value?.isComplete == true
                ? _SystemBrowserButton(contentHash: contentHash)
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: entry.when(
        data: (value) {
          if (value == null) {
            return const Center(child: Text('Cached page not found.'));
          }
          if (!value.isComplete) {
            return _PartialPageState(entry: value);
          }
          return _WebViewBody(contentHash: contentHash, title: value.title);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Page error: $error')),
      ),
    );
  }
}

class _WebViewBody extends ConsumerStatefulWidget {
  const _WebViewBody({required this.contentHash, required this.title});

  final String contentHash;
  final String title;

  @override
  ConsumerState<_WebViewBody> createState() => _WebViewBodyState();
}

class _WebViewBodyState extends ConsumerState<_WebViewBody> {
  WebViewController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(controller: controller);
  }

  Future<void> _loadHtml() async {
    final bytes = await ref
        .read(contentStoreProvider)
        .read(contentHash: widget.contentHash);
    if (!mounted) {
      return;
    }
    if (bytes == null) {
      setState(() => _error = 'Cached HTML bytes are not available.');
      return;
    }
    final html = utf8.decode(bytes);
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..loadHtmlString(html);
    setState(() => _controller = controller);
  }
}

class _PartialPageState extends StatelessWidget {
  const _PartialPageState({required this.entry});

  final WebIndexEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            entry.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF214B2A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(entry.url, style: const TextStyle(color: Color(0xFF2F7A3A))),
          const SizedBox(height: 20),
          Text(entry.snippet),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: entry.expectedChunkCount <= 0
                ? null
                : (entry.receivedChunkCount / entry.expectedChunkCount)
                      .clamp(0, 1)
                      .toDouble(),
          ),
          const SizedBox(height: 12),
          Text(
            '${entry.receivedChunkCount}/${entry.expectedChunkCount} chunks available',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SystemBrowserButton extends ConsumerWidget {
  const _SystemBrowserButton({required this.contentHash});

  final String contentHash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Open in system browser',
      color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.45),
      onPressed: () async {
        final metadata = await ref
            .read(bundleRepositoryProvider)
            .getContentMetadata(contentHash);
        final path = metadata?.localPath;
        if (path == null || path.isEmpty) {
          return;
        }
        await launchUrl(
          Uri.file(File(path).absolute.path),
          mode: LaunchMode.externalApplication,
        );
      },
      icon: const Icon(Icons.open_in_browser_rounded),
    );
  }
}
