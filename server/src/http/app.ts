import cors from '@fastify/cors';
import Fastify, { type FastifyInstance } from 'fastify';
import type { SyncService } from '../services/syncService.js';
import { fetchQuerySchema, uploadRequestSchema } from '../types/bundle.js';

export function buildApp(syncService: SyncService): FastifyInstance {
  const app = Fastify({ logger: false });

  void app.register(cors, { origin: true });

  app.get('/health', async () => ({ ok: true }));

  app.post('/sync/upload', async (request, reply) => {
    const parsed = uploadRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({
        error: 'invalid_upload_request',
        issues: parsed.error.issues
      });
    }
    return syncService.uploadBundles(parsed.data.bundles);
  });

  app.get('/sync/fetch', async (request, reply) => {
    const parsed = fetchQuerySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({
        error: 'invalid_fetch_query',
        issues: parsed.error.issues
      });
    }
    return syncService.fetchRemoteBundles(parsed.data.sinceMs);
  });

  return app;
}
