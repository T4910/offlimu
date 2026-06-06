import { z } from 'zod';

const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(7774),
  DATABASE_URL: z.string().optional(),
  SERVER_NODE_ID: z.string().default('server-gateway'),
  SERVER_PRIVATE_KEY_SEED_BASE64: z.string().optional(),
  OPENING_GRANT_MINOR_UNITS: z.coerce.number().int().nonnegative().default(5000)
});

export type ServerEnv = z.infer<typeof envSchema>;

export function readEnv(source: NodeJS.ProcessEnv = process.env): ServerEnv {
  return envSchema.parse(source);
}
