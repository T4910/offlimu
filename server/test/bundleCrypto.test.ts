import { describe, expect, it } from 'vitest';
import { verifyBundleSignature } from '../src/crypto/bundleCrypto.js';
import { fromWireBundle } from '../src/types/bundle.js';
import { makeClientIdentity, walletSpendBundle } from './helpers.js';

describe('bundle crypto compatibility', () => {
  it('verifies client-shaped Ed25519 bundle signatures', () => {
    const client = makeClientIdentity(7);
    const wire = walletSpendBundle({ source: client });

    expect(verifyBundleSignature(fromWireBundle(wire))).toBe(true);
  });

  it('rejects tampered payloads', () => {
    const client = makeClientIdentity(7);
    const wire = walletSpendBundle({ source: client });
    wire.payload = '{"kind":"spend","amountMinorUnits":999999}';

    expect(verifyBundleSignature(fromWireBundle(wire))).toBe(false);
  });
});
