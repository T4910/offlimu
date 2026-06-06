import { createHash } from 'node:crypto';
import nacl from 'tweetnacl';
import {
  type Bundle,
  legacySignaturePayload,
  signaturePayload
} from '../types/bundle.js';

export type ServerIdentity = {
  nodeId: string;
  publicKeyBase64: string;
  seedBase64: string;
};

export function createServerIdentity(params: {
  nodeId: string;
  seedBase64?: string | null;
}): ServerIdentity {
  const seed = params.seedBase64
    ? Buffer.from(params.seedBase64, 'base64')
    : createHash('sha256').update('offlimu-dev-server-seed').digest();

  if (seed.length !== 32) {
    throw new Error('SERVER_PRIVATE_KEY_SEED_BASE64 must decode to 32 bytes');
  }

  const keyPair = nacl.sign.keyPair.fromSeed(seed);
  return {
    nodeId: params.nodeId,
    publicKeyBase64: Buffer.from(keyPair.publicKey).toString('base64'),
    seedBase64: Buffer.from(seed).toString('base64')
  };
}

export function verifyBundleSignature(bundle: Bundle): boolean {
  if (!bundle.signature || !bundle.sourcePublicKey) return false;
  const publicKey = Buffer.from(bundle.sourcePublicKey, 'base64');
  const signature = Buffer.from(bundle.signature, 'base64');
  if (publicKey.length !== 32 || signature.length !== 64) return false;

  const currentPayload = Buffer.from(signaturePayload(bundle), 'utf8');
  if (nacl.sign.detached.verify(currentPayload, signature, publicKey)) {
    return true;
  }

  const legacyPayload = Buffer.from(legacySignaturePayload(bundle), 'utf8');
  return nacl.sign.detached.verify(legacyPayload, signature, publicKey);
}

export function signBundle(bundle: Bundle, identity: ServerIdentity): Bundle {
  const seed = Buffer.from(identity.seedBase64, 'base64');
  const keyPair = nacl.sign.keyPair.fromSeed(seed);
  const signedPayloadBundle: Bundle = {
    ...bundle,
    sourcePublicKey: identity.publicKeyBase64
  };
  const signature = nacl.sign.detached(
    Buffer.from(signaturePayload(signedPayloadBundle), 'utf8'),
    keyPair.secretKey
  );
  return {
    ...signedPayloadBundle,
    signature: Buffer.from(signature).toString('base64')
  };
}

export function sha256Hex(input: string): string {
  return createHash('sha256').update(input).digest('hex');
}
