import type { Bundle } from '../types/bundle.js';
import type {
  AuditEvent,
  SyncStore,
  UploadedBundleRecord,
  WalletLedgerEvent,
  WebSearchRequestRecord,
  WebSearchResultRecord
} from '../db/store.js';

export type AdminSummary = {
  generatedAtMs: number;
  metrics: {
    totalUploads: number;
    rejectedUploads: number;
    ledgerVolumeMinorUnits: number;
    activeNodes: number;
    webRequests: number;
    outboxSize: number;
    recentErrors: number;
  };
  recent: {
    auditEvents: AuditEvent[];
    uploadedBundles: UploadedBundleRecord[];
    webSearches: AdminWebSearchRow[];
  };
};

export type AdminWebSearchRow = WebSearchRequestRecord & {
  resultCount: number;
  results: WebSearchResultRecord[];
};

export class AdminService {
  constructor(private readonly store: SyncStore) {}

  async summary(): Promise<AdminSummary> {
    const [uploads, ledger, webRequests, outbox, auditEvents] =
      await Promise.all([
        this.store.listUploadedBundles({ limit: 500 }),
        this.store.listWalletEvents({ limit: 500 }),
        this.store.listWebSearchRequests({ limit: 500 }),
        this.store.listOutboxBundles({ limit: 500 }),
        this.store.listAuditEvents({ limit: 500 })
      ]);

    const recentWebSearches = await this.webSearches({ limit: 5 });
    const activeNodes = new Set<string>();
    for (const upload of uploads) activeNodes.add(upload.sourceNodeId);
    for (const event of ledger) activeNodes.add(event.nodeId);

    return {
      generatedAtMs: Date.now(),
      metrics: {
        totalUploads: uploads.length,
        rejectedUploads: uploads.filter(
          (upload) =>
            upload.processingStatus === 'rejected' || !upload.signatureValid
        ).length,
        ledgerVolumeMinorUnits: ledger.reduce(
          (sum, event) => sum + Math.abs(event.balanceImpactMinorUnits),
          0
        ),
        activeNodes: activeNodes.size,
        webRequests: webRequests.length,
        outboxSize: outbox.length,
        recentErrors: auditEvents.filter(isErrorAudit).length
      },
      recent: {
        auditEvents: auditEvents.slice(0, 5),
        uploadedBundles: uploads.slice(0, 5),
        webSearches: recentWebSearches
      }
    };
  }

  ledger(filters: {
    limit?: number;
    nodeId?: string;
    kind?: WalletLedgerEvent['kind'];
    status?: WalletLedgerEvent['status'];
  } = {}): Promise<WalletLedgerEvent[]> {
    return this.store.listWalletEvents(filters);
  }

  bundles(filters: {
    limit?: number;
    type?: string;
    processingStatus?: UploadedBundleRecord['processingStatus'];
    signatureValid?: boolean;
  } = {}): Promise<UploadedBundleRecord[]> {
    return this.store.listUploadedBundles(filters);
  }

  outbox(filters: {
    limit?: number;
    type?: string;
    destinationNodeId?: string;
  } = {}): Promise<Bundle[]> {
    return this.store.listOutboxBundles(filters);
  }

  audit(filters: {
    limit?: number;
    kind?: string;
    nodeId?: string;
  } = {}): Promise<AuditEvent[]> {
    return this.store.listAuditEvents(filters);
  }

  async webSearches(filters: {
    limit?: number;
    requesterNodeId?: string;
    status?: WebSearchRequestRecord['status'];
    query?: string;
  } = {}): Promise<AdminWebSearchRow[]> {
    const requests = await this.store.listWebSearchRequests(filters);
    return Promise.all(
      requests.map(async (request) => {
        const results = await this.store.listWebSearchResults({
          requestBundleId: request.bundleId,
          limit: 20
        });
        return {
          ...request,
          resultCount: results.length,
          results
        };
      })
    );
  }
}

function isErrorAudit(event: AuditEvent): boolean {
  const text = `${event.kind} ${event.message}`.toLowerCase();
  return (
    text.includes('reject') ||
    text.includes('fail') ||
    text.includes('error') ||
    text.includes('invalid')
  );
}
