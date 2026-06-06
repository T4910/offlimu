import type { FastifyInstance } from 'fastify';
import type { AdminService, AdminSummary, AdminWebSearchRow } from './adminService.js';
import type { AuditEvent, UploadedBundleRecord, WalletLedgerEvent } from '../db/store.js';
import type { Bundle } from '../types/bundle.js';

export function registerAdminRoutes(app: FastifyInstance, admin: AdminService): void {
  app.get('/admin', async (_request, reply) => {
    const summary = await admin.summary();
    return reply.type('text/html').send(renderDashboard(summary));
  });

  app.get('/admin/ledger', async (request, reply) => {
    const filters = queryFilters(request.query);
    const rows = await admin.ledger({
      limit: filters.limit,
      nodeId: filters.nodeId,
      kind: filters.kind as WalletLedgerEvent['kind'] | undefined,
      status: filters.status as WalletLedgerEvent['status'] | undefined
    });
    return reply.type('text/html').send(renderLedger(rows, filters));
  });

  app.get('/admin/web-searches', async (request, reply) => {
    const filters = queryFilters(request.query);
    const rows = await admin.webSearches({
      limit: filters.limit,
      requesterNodeId: filters.requesterNodeId,
      status: filters.status as AdminWebSearchRow['status'] | undefined,
      query: filters.query
    });
    return reply.type('text/html').send(renderWebSearches(rows, filters));
  });

  app.get('/admin/bundles', async (request, reply) => {
    const filters = queryFilters(request.query);
    const rows = await admin.bundles({
      limit: filters.limit,
      type: filters.type,
      processingStatus: filters.status as UploadedBundleRecord['processingStatus'] | undefined,
      signatureValid: parseBool(filters.signatureValid)
    });
    return reply.type('text/html').send(renderBundles(rows, filters));
  });

  app.get('/admin/outbox', async (request, reply) => {
    const filters = queryFilters(request.query);
    const rows = await admin.outbox({
      limit: filters.limit,
      type: filters.type,
      destinationNodeId: filters.destinationNodeId
    });
    return reply.type('text/html').send(renderOutbox(rows, filters));
  });

  app.get('/admin/audit', async (request, reply) => {
    const filters = queryFilters(request.query);
    const rows = await admin.audit({
      limit: filters.limit,
      kind: filters.kind,
      nodeId: filters.nodeId
    });
    return reply.type('text/html').send(renderAudit(rows, filters));
  });

  app.get('/admin/api/summary', async () => admin.summary());
  app.get('/admin/api/ledger', async (request) => {
    const filters = queryFilters(request.query);
    return admin.ledger({
      limit: filters.limit,
      nodeId: filters.nodeId,
      kind: filters.kind as WalletLedgerEvent['kind'] | undefined,
      status: filters.status as WalletLedgerEvent['status'] | undefined
    });
  });
  app.get('/admin/api/web-searches', async (request) => {
    const filters = queryFilters(request.query);
    return admin.webSearches({
      limit: filters.limit,
      requesterNodeId: filters.requesterNodeId,
      status: filters.status as AdminWebSearchRow['status'] | undefined,
      query: filters.query
    });
  });
  app.get('/admin/api/bundles', async (request) => {
    const filters = queryFilters(request.query);
    return admin.bundles({
      limit: filters.limit,
      type: filters.type,
      processingStatus: filters.status as UploadedBundleRecord['processingStatus'] | undefined,
      signatureValid: parseBool(filters.signatureValid)
    });
  });
  app.get('/admin/api/outbox', async (request) => {
    const filters = queryFilters(request.query);
    return admin.outbox({
      limit: filters.limit,
      type: filters.type,
      destinationNodeId: filters.destinationNodeId
    });
  });
  app.get('/admin/api/audit', async (request) => {
    const filters = queryFilters(request.query);
    return admin.audit({
      limit: filters.limit,
      kind: filters.kind,
      nodeId: filters.nodeId
    });
  });
}

type QueryFilters = Record<string, string | undefined> & { limit?: number };

function queryFilters(raw: unknown): QueryFilters {
  const query = raw && typeof raw === 'object' ? raw as Record<string, unknown> : {};
  const filters: QueryFilters = {};
  for (const [key, value] of Object.entries(query)) {
    if (typeof value === 'string' && value.trim()) filters[key] = value.trim();
  }
  const limit = Number(filters.limit);
  filters.limit = Number.isFinite(limit) && limit > 0 ? Math.min(Math.trunc(limit), 500) : 50;
  return filters;
}

function parseBool(value?: string): boolean | undefined {
  if (value === 'true') return true;
  if (value === 'false') return false;
  return undefined;
}

function renderDashboard(summary: AdminSummary): string {
  return layout('Dashboard', `
    <section class="cards">
      ${metric('Total uploads', summary.metrics.totalUploads)}
      ${metric('Rejected uploads', summary.metrics.rejectedUploads)}
      ${metric('Ledger volume', formatDtn(summary.metrics.ledgerVolumeMinorUnits))}
      ${metric('Active nodes', summary.metrics.activeNodes)}
      ${metric('Web requests', summary.metrics.webRequests)}
      ${metric('Outbox bundles', summary.metrics.outboxSize)}
      ${metric('Recent errors', summary.metrics.recentErrors)}
    </section>
    <section class="grid">
      ${panel('Recent Uploaded Bundles', bundleTable(summary.recent.uploadedBundles))}
      ${panel('Recent Web Searches', webSearchTable(summary.recent.webSearches))}
      ${panel('Recent Audit Events', auditTable(summary.recent.auditEvents))}
    </section>
  `);
}

function renderLedger(rows: WalletLedgerEvent[], filters: QueryFilters): string {
  return layout('Main Ledger', `
    ${filterForm('/admin/ledger', [
      input('nodeId', filters.nodeId, 'Node ID'),
      input('kind', filters.kind, 'Kind'),
      input('status', filters.status, 'Status'),
      input('limit', String(filters.limit ?? 50), 'Limit')
    ])}
    ${panel('Wallet Ledger', ledgerTable(rows))}
  `);
}

function renderWebSearches(rows: AdminWebSearchRow[], filters: QueryFilters): string {
  return layout('Circulating Web Searches', `
    ${filterForm('/admin/web-searches', [
      input('query', filters.query, 'Query'),
      input('requesterNodeId', filters.requesterNodeId, 'Requester'),
      input('status', filters.status, 'Status'),
      input('limit', String(filters.limit ?? 50), 'Limit')
    ])}
    ${panel('Web Searches', webSearchTable(rows))}
  `);
}

function renderBundles(rows: UploadedBundleRecord[], filters: QueryFilters): string {
  return layout('Uploaded Bundles', `
    ${filterForm('/admin/bundles', [
      input('type', filters.type, 'Type'),
      input('status', filters.status, 'Status'),
      input('signatureValid', filters.signatureValid, 'Signature true/false'),
      input('limit', String(filters.limit ?? 50), 'Limit')
    ])}
    ${panel('Uploaded Bundles', bundleTable(rows))}
  `);
}

function renderOutbox(rows: Bundle[], filters: QueryFilters): string {
  return layout('Server Outbox', `
    ${filterForm('/admin/outbox', [
      input('type', filters.type, 'Type'),
      input('destinationNodeId', filters.destinationNodeId, 'Destination'),
      input('limit', String(filters.limit ?? 50), 'Limit')
    ])}
    ${panel('Outbox Bundles', outboxTable(rows))}
  `);
}

function renderAudit(rows: AuditEvent[], filters: QueryFilters): string {
  return layout('Audit Logs', `
    ${filterForm('/admin/audit', [
      input('kind', filters.kind, 'Kind'),
      input('nodeId', filters.nodeId, 'Node ID'),
      input('limit', String(filters.limit ?? 50), 'Limit')
    ])}
    ${panel('Audit Logs', auditTable(rows))}
  `);
}

function layout(title: string, body: string): string {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>OffLiMU Admin - ${escapeHtml(title)}</title>
  <style>
    :root { color-scheme: light; --bg:#f5f8f2; --card:#fff; --ink:#1f3524; --muted:#5f735d; --line:#d8e7d2; --accent:#2e7d32; }
    * { box-sizing: border-box; }
    body { margin: 0; font: 14px/1.45 Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: var(--ink); background: var(--bg); }
    header { position: sticky; top: 0; z-index: 1; background: rgba(245,248,242,.94); border-bottom: 1px solid var(--line); backdrop-filter: blur(10px); }
    .bar { max-width: 1180px; margin: 0 auto; padding: 14px 18px; display: flex; gap: 16px; align-items: center; }
    h1 { margin: 0; font-size: 20px; letter-spacing: 0; }
    nav { display: flex; gap: 8px; flex-wrap: wrap; margin-left: auto; }
    a, button { color: var(--accent); }
    nav a, .button { text-decoration: none; border: 1px solid var(--line); background: var(--card); padding: 7px 10px; border-radius: 8px; font-weight: 700; }
    main { max-width: 1180px; margin: 0 auto; padding: 18px; }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; margin-bottom: 14px; }
    .card, .panel, form { background: var(--card); border: 1px solid var(--line); border-radius: 8px; box-shadow: 0 10px 24px rgba(25, 65, 35, .06); }
    .card { padding: 14px; }
    .metric { color: var(--muted); font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: .08em; }
    .value { margin-top: 8px; font-size: 24px; font-weight: 850; }
    .grid { display: grid; gap: 14px; }
    .panel { overflow: hidden; }
    .panel h2 { margin: 0; padding: 12px 14px; border-bottom: 1px solid var(--line); font-size: 15px; }
    form { display: flex; gap: 10px; flex-wrap: wrap; padding: 12px; margin-bottom: 14px; align-items: end; }
    label { display: grid; gap: 4px; color: var(--muted); font-size: 12px; font-weight: 700; }
    input { min-width: 130px; border: 1px solid var(--line); border-radius: 8px; padding: 8px; color: var(--ink); }
    button { border: 0; background: var(--accent); color: white; border-radius: 8px; padding: 9px 12px; font-weight: 800; }
    table { width: 100%; border-collapse: collapse; }
    th, td { text-align: left; padding: 10px 12px; border-bottom: 1px solid var(--line); vertical-align: top; }
    th { color: var(--muted); font-size: 12px; text-transform: uppercase; letter-spacing: .06em; }
    code { overflow-wrap: anywhere; color: #244b2b; }
    .muted { color: var(--muted); }
    .pill { display: inline-block; border: 1px solid var(--line); border-radius: 999px; padding: 2px 7px; background: #f0f7ee; font-weight: 700; }
    details { max-width: 380px; }
    pre { white-space: pre-wrap; overflow-wrap: anywhere; max-height: 260px; overflow: auto; background: #f7fbf5; border: 1px solid var(--line); border-radius: 8px; padding: 8px; }
  </style>
</head>
<body>
  <header><div class="bar"><h1>OffLiMU Admin</h1><nav>${nav()}</nav><button onclick="location.reload()">Refresh</button></div></header>
  <main><h1>${escapeHtml(title)}</h1><p class="muted">Local sync-server operational view.</p>${body}</main>
</body>
</html>`;
}

function nav(): string {
  return [
    ['/admin', 'Dashboard'],
    ['/admin/ledger', 'Ledger'],
    ['/admin/web-searches', 'Web Searches'],
    ['/admin/bundles', 'Bundles'],
    ['/admin/outbox', 'Outbox'],
    ['/admin/audit', 'Audit']
  ].map(([href, label]) => `<a href="${href}">${label}</a>`).join('');
}

function metric(label: string, value: string | number): string {
  return `<div class="card"><div class="metric">${escapeHtml(label)}</div><div class="value">${escapeHtml(String(value))}</div></div>`;
}

function panel(title: string, content: string): string {
  return `<section class="panel"><h2>${escapeHtml(title)}</h2>${content}</section>`;
}

function filterForm(action: string, controls: string[]): string {
  return `<form method="get" action="${action}">${controls.join('')}<button type="submit">Apply</button><a class="button" href="${action}">Clear</a></form>`;
}

function input(name: string, value: string | undefined, label: string): string {
  return `<label>${escapeHtml(label)}<input name="${name}" value="${escapeHtml(value ?? '')}"></label>`;
}

function ledgerTable(rows: WalletLedgerEvent[]): string {
  return table(
    ['Time', 'Node', 'Kind', 'Status', 'Amount', 'Impact', 'Counterparty', 'Source'],
    rows.map((row) => [
      fmtTime(row.createdAtMs),
      code(row.nodeId),
      pill(row.kind),
      pill(row.status),
      formatDtn(row.amountMinorUnits),
      formatDtn(row.balanceImpactMinorUnits),
      code(row.counterpartyNodeId ?? '-'),
      code(row.sourceBundleId ?? '-')
    ])
  );
}

function bundleTable(rows: UploadedBundleRecord[]): string {
  return table(
    ['Last Seen', 'Bundle', 'Type', 'Source', 'Signature', 'Status', 'Payload'],
    rows.map((row) => [
      fmtTime(row.lastSeenMs),
      code(row.bundleId),
      pill(row.type),
      code(row.sourceNodeId),
      row.signatureValid ? 'valid' : 'invalid',
      pill(row.processingStatus),
      jsonDetails(row.bundle)
    ])
  );
}

function webSearchTable(rows: AdminWebSearchRow[]): string {
  return table(
    ['Created', 'Query', 'Requester', 'Status', 'Results', 'Content Hashes'],
    rows.map((row) => [
      fmtTime(row.createdAtMs),
      escapeHtml(row.query),
      code(row.requesterNodeId),
      pill(row.status),
      String(row.resultCount),
      row.results.map((result) => code(result.contentHash)).join('<br>')
    ])
  );
}

function outboxTable(rows: Bundle[]): string {
  return table(
    ['Created', 'Bundle', 'Type', 'Destination', 'Ack For', 'Payload'],
    rows.map((row) => [
      fmtTime(row.createdAtMs),
      code(row.bundleId),
      pill(row.type),
      code(row.destinationNodeId ?? 'broadcast'),
      code(row.ackForBundleId ?? '-'),
      jsonDetails(row)
    ])
  );
}

function auditTable(rows: AuditEvent[]): string {
  return table(
    ['Time', 'Kind', 'Node', 'Bundle', 'Message', 'Fields'],
    rows.map((row) => [
      fmtTime(row.createdAtMs),
      pill(row.kind),
      code(row.nodeId ?? '-'),
      code(row.bundleId ?? '-'),
      escapeHtml(row.message),
      row.fields ? jsonDetails(row.fields) : '-'
    ])
  );
}

function table(headers: string[], rows: string[][]): string {
  if (rows.length === 0) return '<p class="muted" style="padding:14px">No records found.</p>';
  return `<table><thead><tr>${headers.map((header) => `<th>${escapeHtml(header)}</th>`).join('')}</tr></thead><tbody>${rows.map((row) => `<tr>${row.map((cell) => `<td>${cell}</td>`).join('')}</tr>`).join('')}</tbody></table>`;
}

function pill(value: string): string {
  return `<span class="pill">${escapeHtml(value)}</span>`;
}

function code(value: string): string {
  return `<code>${escapeHtml(value)}</code>`;
}

function jsonDetails(value: unknown): string {
  return `<details><summary>JSON</summary><pre>${escapeHtml(JSON.stringify(value, null, 2))}</pre></details>`;
}

function fmtTime(ms: number): string {
  const value = typeof ms === 'number' ? ms : Number(ms);
  if (!Number.isFinite(value) || value <= 0) {
    return '-';
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return '-';
  }
  return date.toISOString().replace('T', ' ').replace('.000Z', 'Z');
}

function formatDtn(minorUnits: number): string {
  return `${(minorUnits / 100).toFixed(2)} DTN`;
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
