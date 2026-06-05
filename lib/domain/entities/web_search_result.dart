class WebSearchResult {
  const WebSearchResult({
    required this.requestBundleId,
    required this.query,
    required this.title,
    required this.url,
    required this.snippet,
    required this.html,
  });

  final String requestBundleId;
  final String query;
  final String title;
  final String url;
  final String snippet;
  final String html;
}
