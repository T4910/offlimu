import { z } from 'zod';

const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(7774),
  DATABASE_URL: z.string().optional(),
  SERVER_NODE_ID: z.string().default('server-gateway'),
  SERVER_PRIVATE_KEY_SEED_BASE64: z.string().optional(),
  OPENING_GRANT_MINOR_UNITS: z.coerce.number().int().nonnegative().default(5000),
  WEB_SEARCH_PROVIDER: z.enum(['google', 'mock']).default('mock'),
  GOOGLE_CSE_API_KEY: z.string().optional(),
  GOOGLE_CSE_ID: z.string().optional(),
  WEB_SEARCH_MAX_RESULTS: z.coerce.number().int().positive().default(3),
  WEB_SCRAPE_TIMEOUT_MS: z.coerce.number().int().positive().default(8000),
  WEB_SCRAPE_MAX_BYTES: z.coerce.number().int().positive().default(1_000_000),
  WEB_SCRAPER_USER_AGENT: z
    .string()
    .default('OffLiMU-SyncServer/0.1 (+https://offlimu.local)')
});

export type ServerEnv = z.infer<typeof envSchema>;

export function readEnv(source: NodeJS.ProcessEnv = process.env): ServerEnv {
  return envSchema.parse(source);
}
