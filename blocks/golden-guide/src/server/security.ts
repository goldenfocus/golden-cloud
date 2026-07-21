import { createHash, createHmac, randomBytes, timingSafeEqual } from 'node:crypto';

function sign(nonce: string, name: string, secret: string): string {
  return createHmac('sha256', secret).update(`${nonce}:${name}`).digest('hex').slice(0, 16);
}

/** Server-minted, HMAC-signed tool-call ID. Clients cannot forge tool_results for calls never issued. */
export function mintCallId(name: string, secret: string): string {
  const nonce = randomBytes(8).toString('hex');
  return `${nonce}.${sign(nonce, name, secret)}`;
}

export function verifyCallId(callId: string, name: string, secret: string): boolean {
  const [nonce, sig] = callId.split('.');
  if (!nonce || !sig) return false;
  const expected = sign(nonce, name, secret);
  if (sig.length !== expected.length) return false;
  return timingSafeEqual(Buffer.from(sig), Buffer.from(expected));
}

/** Stable fallback secret so hosts need no extra env var: derived from the brain API key. */
export function deriveSecret(seed: string): string {
  return createHash('sha256').update(`golden-guide:${seed}`).digest('hex');
}
