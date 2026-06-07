import { Buffer } from 'node:buffer';
import * as cheerio from 'cheerio';
import sanitizeHtml from 'sanitize-html';

export type SearchCandidate = {
  title: string;
  url: string;
  snippet: string;
  rank: number;
  provider: string;
};

export type SearchProvider = {
  readonly name: string;
  search(params: {
    query: string;
    maxResults: number;
  }): Promise<SearchCandidate[]>;
};

export type SnapshotResult = {
  title: string;
  url: string;
  snippet: string;
  html: string;
  error?: string | null;
};

export type WebSearchPipelineOptions = {
  provider: 'google' | 'mock';
  googleApiKey?: string;
  googleCseId?: string;
  maxResults: number;
  scrapeTimeoutMs: number;
  scrapeMaxBytes: number;
  scraperUserAgent: string;
  fetchImpl?: typeof fetch;
};

export class GoogleSearchProvider implements SearchProvider {
  readonly name = 'google';

  constructor(
    private readonly params: {
      apiKey: string;
      cseId: string;
      fetchImpl?: typeof fetch;
    }
  ) {}

  async search(params: {
    query: string;
    maxResults: number;
  }): Promise<SearchCandidate[]> {
    const url = new URL('https://www.googleapis.com/customsearch/v1');
    url.searchParams.set('key', this.params.apiKey);
    url.searchParams.set('cx', this.params.cseId);
    url.searchParams.set('q', params.query);
    url.searchParams.set('num', String(Math.min(params.maxResults, 10)));

    const response = await (this.params.fetchImpl ?? fetch)(url);
    if (!response.ok) {
      throw new Error(`Google search failed with HTTP ${response.status}.`);
    }

    const body = await response.json() as {
      items?: Array<{
        title?: string;
        link?: string;
        snippet?: string;
      }>;
    };

    return (body.items ?? [])
      .filter((item) => typeof item.link === 'string' && item.link.length > 0)
      .slice(0, params.maxResults)
      .map((item, index) => ({
        title: item.title?.trim() || `Search result ${index + 1}`,
        url: item.link!,
        snippet: item.snippet?.trim() || '',
        rank: index + 1,
        provider: this.name
      }));
  }
}

export class MockSearchProvider implements SearchProvider {
  readonly name = 'mock';

  async search(params: {
    query: string;
    maxResults: number;
  }): Promise<SearchCandidate[]> {
    return Array.from({ length: params.maxResults }, (_, index) => {
      const ordinal = index + 1;
      return {
        title: `Offline result ${ordinal} for ${params.query}`,
        url: `https://mock.offlimu.local/search/${encodeURIComponent(params.query)}/${ordinal}`,
        snippet: `A server-generated cached page about "${params.query}".`,
        rank: ordinal,
        provider: this.name
      };
    });
  }
}

export class PageSnapshotter {
  constructor(
    private readonly params: {
      timeoutMs: number;
      maxBytes: number;
      userAgent: string;
      fetchImpl?: typeof fetch;
    }
  ) {}

  async snapshot(params: {
    query: string;
    candidate: SearchCandidate;
  }): Promise<SnapshotResult> {
    const { query, candidate } = params;

    if (candidate.provider === 'mock') {
      return {
        title: candidate.title,
        url: candidate.url,
        snippet: candidate.snippet,
        html: mockHtml({
          title: candidate.title,
          url: candidate.url,
          query,
          snippet: candidate.snippet,
          ordinal: candidate.rank
        })
      };
    }

    const parsedUrl = parseHttpUrl(candidate.url);
    if (!parsedUrl) {
      return fallbackSnapshot({ query, candidate, reason: 'invalid_url' });
    }

    try {
      const allowed = await this.canCrawl(parsedUrl);
      if (!allowed) {
        return fallbackSnapshot({ query, candidate, reason: 'robots_disallowed' });
      }

      const html = await this.fetchHtml(parsedUrl);
      return buildReadableSnapshot({ query, candidate, rawHtml: html });
    } catch (error) {
      return fallbackSnapshot({
        query,
        candidate,
        reason: scrapeErrorReason(error)
      });
    }
  }

  private async canCrawl(url: URL): Promise<boolean> {
    const robotsUrl = new URL('/robots.txt', url.origin);
    try {
      const response = await this.fetchWithTimeout(robotsUrl, {
        redirect: 'follow',
        headers: { 'user-agent': this.params.userAgent }
      });
      if (!response.ok) {
        return true;
      }
      const body = await response.text();
      return isPathAllowedByRobots({
        robotsText: body,
        userAgent: this.params.userAgent,
        path: `${url.pathname}${url.search}`
      });
    } catch {
      return true;
    }
  }

  private async fetchHtml(url: URL): Promise<string> {
    const response = await this.fetchWithTimeout(url, {
      redirect: 'follow',
      headers: {
        accept: 'text/html,application/xhtml+xml',
        'user-agent': this.params.userAgent
      }
    });

    if (!response.ok) {
      throw new ScrapeError('fetch_failed');
    }

    const contentType = response.headers.get('content-type') ?? '';
    if (
      !contentType.toLowerCase().includes('text/html') &&
      !contentType.toLowerCase().includes('application/xhtml+xml')
    ) {
      throw new ScrapeError('non_html_content');
    }

    return readBoundedText(response, this.params.maxBytes);
  }

  private async fetchWithTimeout(
    url: URL,
    init: RequestInit
  ): Promise<Response> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.params.timeoutMs);
    try {
      return await (this.params.fetchImpl ?? fetch)(url, {
        ...init,
        signal: controller.signal
      });
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        throw new ScrapeError('timeout');
      }
      throw error;
    } finally {
      clearTimeout(timer);
    }
  }
}

export function createSearchProvider(
  options: WebSearchPipelineOptions
): SearchProvider {
  if (
    options.provider === 'google' &&
    options.googleApiKey &&
    options.googleCseId
  ) {
    return new GoogleSearchProvider({
      apiKey: options.googleApiKey,
      cseId: options.googleCseId,
      fetchImpl: options.fetchImpl
    });
  }
  return new MockSearchProvider();
}

export function createSnapshotter(
  options: WebSearchPipelineOptions
): PageSnapshotter {
  return new PageSnapshotter({
    timeoutMs: options.scrapeTimeoutMs,
    maxBytes: options.scrapeMaxBytes,
    userAgent: options.scraperUserAgent,
    fetchImpl: options.fetchImpl
  });
}

export function fallbackSnapshot(params: {
  query: string;
  candidate: SearchCandidate;
  reason: string;
}): SnapshotResult {
  const title = `Offline fallback for ${params.candidate.title || params.query}`;
  return {
    title,
    url: params.candidate.url,
    snippet: params.candidate.snippet || `Could not scrape this page: ${params.reason}.`,
    error: params.reason,
    html: `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(title)}</title>
  ${snapshotStyle()}
</head>
<body>
  <main>
    <header>
      <p class="source">${escapeHtml(params.candidate.url)}</p>
      <h1>${escapeHtml(title)}</h1>
      <p>${escapeHtml(params.candidate.snippet)}</p>
    </header>
    <article>
      <p>This offline snapshot was generated as a fallback for <strong>${escapeHtml(params.query)}</strong>.</p>
      <p>The server could not safely scrape the source page.</p>
      <p><strong>Reason:</strong> ${escapeHtml(params.reason)}</p>
    </article>
  </main>
</body>
</html>`
  };
}

function buildReadableSnapshot(params: {
  query: string;
  candidate: SearchCandidate;
  rawHtml: string;
}): SnapshotResult {
  const $ = cheerio.load(params.rawHtml);
  $('script, iframe, object, embed, noscript, style, link, meta, form').remove();

  const discoveredTitle =
    $('title').first().text().trim() ||
    $('h1').first().text().trim() ||
    params.candidate.title;
  const articleSource =
    $('article').first().html() ||
    $('main').first().html() ||
    $('body').html() ||
    '';

  const cleanArticle = sanitizeHtml(articleSource, {
    allowedTags: [
      'article',
      'section',
      'header',
      'main',
      'p',
      'br',
      'blockquote',
      'pre',
      'code',
      'strong',
      'em',
      'b',
      'i',
      'ul',
      'ol',
      'li',
      'h1',
      'h2',
      'h3',
      'h4',
      'table',
      'thead',
      'tbody',
      'tr',
      'th',
      'td',
      'a'
    ],
    allowedAttributes: {
      a: ['href']
    },
    allowedSchemes: ['http', 'https', 'mailto'],
    transformTags: {
      a: sanitizeHtml.simpleTransform('a', { rel: 'nofollow noopener' })
    }
  }).trim();

  if (!cleanArticle) {
    throw new ScrapeError('sanitize_failed');
  }

  const title = discoveredTitle || params.candidate.title;
  return {
    title,
    url: params.candidate.url,
    snippet: params.candidate.snippet,
    html: `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(title)}</title>
  ${snapshotStyle()}
</head>
<body>
  <main>
    <header>
      <p class="source">${escapeHtml(params.candidate.url)}</p>
      <h1>${escapeHtml(title)}</h1>
      <p>${escapeHtml(params.candidate.snippet)}</p>
    </header>
    <article>${cleanArticle}</article>
  </main>
</body>
</html>`
  };
}

function mockHtml(params: {
  title: string;
  url: string;
  query: string;
  snippet: string;
  ordinal: number;
}): string {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(params.title)}</title>
  ${snapshotStyle()}
</head>
<body>
  <main>
    <header>
      <p class="source">${escapeHtml(params.url)}</p>
      <h1>${escapeHtml(params.title)}</h1>
      <p>${escapeHtml(params.snippet)}</p>
    </header>
    <article>
      <p>This deterministic server snapshot was generated for <strong>${escapeHtml(params.query)}</strong>.</p>
      <p>Result ${params.ordinal} exercises the real OffLiMU sync-server search pipeline while live scraping is unavailable or unconfigured.</p>
    </article>
  </main>
</body>
</html>`;
}

function snapshotStyle(): string {
  return `<style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 0; color: #1f3524; background: #f6fbf4; }
    main { max-width: 760px; margin: 0 auto; padding: 32px 20px; }
    header { border-bottom: 1px solid #cfe3c8; margin-bottom: 24px; padding-bottom: 20px; }
    .source { color: #53715a; font-size: 14px; word-break: break-all; }
    article { line-height: 1.65; font-size: 17px; }
    img, video, audio, canvas, svg { display: none; }
    pre, code { white-space: pre-wrap; overflow-wrap: anywhere; }
    a { color: #2e7d32; }
  </style>`;
}

async function readBoundedText(
  response: Response,
  maxBytes: number
): Promise<string> {
  if (!response.body) {
    return response.text();
  }

  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    if (!value) continue;
    total += value.byteLength;
    if (total > maxBytes) {
      await reader.cancel();
      throw new ScrapeError('oversized_page');
    }
    chunks.push(value);
  }
  return Buffer.concat(chunks).toString('utf8');
}

function isPathAllowedByRobots(params: {
  robotsText: string;
  userAgent: string;
  path: string;
}): boolean {
  const groups = parseRobotsGroups(params.robotsText);
  const userAgent = params.userAgent.toLowerCase();
  const relevant = groups.filter((group) =>
    group.agents.some((agent) => agent === '*' || userAgent.includes(agent))
  );
  if (relevant.length === 0) return true;

  let bestRule: { type: 'allow' | 'disallow'; path: string } | undefined;
  for (const group of relevant) {
    for (const rule of group.rules) {
      if (!params.path.startsWith(rule.path)) continue;
      if (!bestRule || rule.path.length > bestRule.path.length) {
        bestRule = rule;
      }
    }
  }
  return !bestRule || bestRule.type === 'allow' || bestRule.path === '';
}

function parseRobotsGroups(robotsText: string): Array<{
  agents: string[];
  rules: Array<{ type: 'allow' | 'disallow'; path: string }>;
}> {
  const groups: Array<{
    agents: string[];
    rules: Array<{ type: 'allow' | 'disallow'; path: string }>;
  }> = [];
  let current:
    | { agents: string[]; rules: Array<{ type: 'allow' | 'disallow'; path: string }> }
    | undefined;

  for (const rawLine of robotsText.split(/\r?\n/)) {
    const line = rawLine.replace(/#.*/, '').trim();
    if (!line) continue;
    const separator = line.indexOf(':');
    if (separator < 0) continue;
    const key = line.slice(0, separator).trim().toLowerCase();
    const value = line.slice(separator + 1).trim();
    if (key === 'user-agent') {
      current = { agents: [value.toLowerCase()], rules: [] };
      groups.push(current);
      continue;
    }
    if (!current) continue;
    if (key === 'allow' || key === 'disallow') {
      current.rules.push({ type: key, path: value });
    }
  }

  return groups;
}

function parseHttpUrl(value: string): URL | null {
  try {
    const url = new URL(value);
    return url.protocol === 'http:' || url.protocol === 'https:' ? url : null;
  } catch {
    return null;
  }
}

function scrapeErrorReason(error: unknown): string {
  if (error instanceof ScrapeError) {
    return error.reason;
  }
  return 'fetch_failed';
}

class ScrapeError extends Error {
  constructor(readonly reason: string) {
    super(reason);
  }
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
