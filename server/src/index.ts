import { Kysely, PostgresDialect } from 'kysely';
import pg from 'pg';
import { AdminService } from './admin/adminService.js';
import { readEnv } from './config/env.js';
import { createServerIdentity } from './crypto/bundleCrypto.js';
import { KyselySyncStore } from './db/kyselyStore.js';
import type { Database } from './db/schema.js';
import { buildApp } from './http/app.js';
import { RewardService } from './services/rewardService.js';
import { SyncService } from './services/syncService.js';
import { WalletService } from './services/walletService.js';
import { createWebSearchServiceFromEnv } from './services/webSearchService.js';

process.loadEnvFile(); 
const env = readEnv(process.env);

if (!env.DATABASE_URL) {
  throw new Error('DATABASE_URL is required for the production server entrypoint.');
}

const db = new Kysely<Database>({
  dialect: new PostgresDialect({
    pool: new pg.Pool({ connectionString: env.DATABASE_URL })
  })
});

const identity = createServerIdentity({
  nodeId: env.SERVER_NODE_ID,
  seedBase64: env.SERVER_PRIVATE_KEY_SEED_BASE64
});
const store = new KyselySyncStore(db);
const wallet = new WalletService(store, identity, env.OPENING_GRANT_MINOR_UNITS);
const rewards = new RewardService(wallet);
const webSearch = createWebSearchServiceFromEnv(store, env);
const sync = new SyncService(store, wallet, rewards, webSearch);
const admin = new AdminService(store);
const app = buildApp(sync, { logger: true, adminService: admin });

await app.listen({ port: env.PORT, host: '0.0.0.0' }).then(() => {
  console.log(`Server is running on port ${env.PORT}`);
}).catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
