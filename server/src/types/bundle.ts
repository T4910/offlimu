import { z } from 'zod';

export const bundleDestinationScopeSchema = z.enum(['direct', 'broadcast']);
export const bundlePrioritySchema = z.enum(['low', 'normal', 'high', 'critical']);

export const wireBundleSchema = z.object({
  bundleId: z.string().min(1),
  type: z.string().min(1),
  sourceNodeId: z.string().min(1),
  sourcePublicKey: z.string().nullable().optional(),
  destinationNodeId: z.string().nullable().optional(),
  destinationScope: bundleDestinationScopeSchema.default('direct'),
  priority: bundlePrioritySchema.default('normal'),
  ackForBundleId: z.string().nullable().optional(),
  payload: z.string().nullable().optional(),
  payloadRef: z.string().nullable().optional(),
  signature: z.string().nullable().optional(),
  appId: z.string().default('offlimu.chat'),
  createdAtMs: z.number().int(),
  expiresAtMs: z.number().int().nullable().optional(),
  ttlSeconds: z.number().int().positive(),
  hopCount: z.number().int().nonnegative().default(0),
  acknowledged: z.boolean().default(false),
  sentAtMs: z.number().int().nullable().optional(),
  failedAttempts: z.number().int().nonnegative().default(0),
  lastError: z.string().nullable().optional()
});

export const uploadRequestSchema = z.object({
  bundles: z.array(wireBundleSchema)
});

export const fetchQuerySchema = z.object({
  sinceMs: z.coerce.number().int().nonnegative().default(0)
});

export type WireBundle = z.infer<typeof wireBundleSchema>;

export type Bundle = Omit<WireBundle, 'payloadRef'> & {
  payloadReference?: string | null;
};

export function fromWireBundle(wire: WireBundle): Bundle {
  const { payloadRef, ...rest } = wire;
  return { ...rest, payloadReference: payloadRef ?? null };
}

export function toWireBundle(bundle: Bundle): WireBundle {
  const { payloadReference, ...rest } = bundle;
  return {
    ...rest,
    payloadRef: payloadReference ?? null
  };
}

export function isExpired(bundle: Bundle, nowMs = Date.now()): boolean {
  const expiresAtMs = bundle.expiresAtMs ?? bundle.createdAtMs + bundle.ttlSeconds * 1000;
  return nowMs > expiresAtMs;
}

export function signaturePayload(bundle: Bundle): string {
  return JSON.stringify({
    bundleId: bundle.bundleId,
    type: bundle.type,
    sourceNodeId: bundle.sourceNodeId,
    sourcePublicKey: bundle.sourcePublicKey ?? null,
    destinationNodeId: bundle.destinationNodeId ?? null,
    destinationScope: bundle.destinationScope,
    priority: bundle.priority,
    ackForBundleId: bundle.ackForBundleId ?? null,
    payload: bundle.payload ?? null,
    payloadReference: bundle.payloadReference ?? null,
    appId: bundle.appId,
    createdAtMs: bundle.createdAtMs,
    expiresAtMs: bundle.expiresAtMs ?? null,
    ttlSeconds: bundle.ttlSeconds
  });
}

export function legacySignaturePayload(bundle: Bundle): string {
  return JSON.stringify({
    bundleId: bundle.bundleId,
    type: bundle.type,
    sourceNodeId: bundle.sourceNodeId,
    sourcePublicKey: bundle.sourcePublicKey ?? null,
    destinationNodeId: bundle.destinationNodeId ?? null,
    destinationScope: bundle.destinationScope,
    priority: bundle.priority,
    ackForBundleId: bundle.ackForBundleId ?? null,
    payload: bundle.payload ?? null,
    payloadReference: bundle.payloadReference ?? null,
    appId: bundle.appId,
    createdAtMs: bundle.createdAtMs,
    expiresAtMs: bundle.expiresAtMs ?? null,
    ttlSeconds: bundle.ttlSeconds,
    hopCount: bundle.hopCount
  });
}

export function parseJsonPayload(bundle: Bundle): Record<string, unknown> | null {
  if (!bundle.payload) return null;
  try {
    const parsed = JSON.parse(bundle.payload);
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
      ? (parsed as Record<string, unknown>)
      : null;
  } catch {
    return null;
  }
}
