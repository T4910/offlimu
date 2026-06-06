import cors from '@fastify/cors';
import Fastify, { type FastifyInstance } from 'fastify';
import type { SyncService } from '../services/syncService.js';
import { fetchQuerySchema, uploadRequestSchema } from '../types/bundle.js';

type BuildAppOptions = {
  logger?: boolean;
};

export function buildApp(
  syncService: SyncService,
  options: BuildAppOptions = {}
): FastifyInstance {
  const app = Fastify({ logger: options.logger ?? false });

  void app.register(cors, { origin: true });

  app.get('/health', async () => ({ ok: true }));

  app.setErrorHandler((error: unknown, request, reply) => {
    const routeError =
      error instanceof Error ? error : new Error(String(error));
    const statusCodeValue = (error as { statusCode?: unknown })?.statusCode;
    request.log.error(
      {
        err: routeError,
        method: request.method,
        url: request.url
      },
      'sync_route_failed'
    );

    const statusCode =
      typeof statusCodeValue === 'number' && statusCodeValue >= 400
        ? statusCodeValue
        : 500;

    return reply.status(statusCode).send({
      error: statusCode >= 500 ? 'sync_server_error' : 'sync_request_error',
      message: routeError.message,
      statusCode
    });
  });

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
