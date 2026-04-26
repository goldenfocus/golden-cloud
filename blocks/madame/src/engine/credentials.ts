/**
 * AES-256-GCM credential envelope.
 *
 * Web Crypto API — works in Vercel Edge, Cloudflare Workers, Node 18+, browsers.
 * 12-byte IV (GCM optimum).  Format: base64(iv):base64(ciphertext+tag)
 *
 * Generate a key:
 *   openssl rand -hex 32
 */

const ALG = 'AES-GCM';
const IV_BYTES = 12;

export async function encryptCredentials(plain: string, keyHex: string): Promise<string> {
  if (keyHex.length !== 64) {
    throw new Error('encryption key must be 32 bytes (64 hex chars)');
  }
  const key = await importKey(keyHex, ['encrypt']);
  const iv = crypto.getRandomValues(new Uint8Array(IV_BYTES));
  const ciphertext = await crypto.subtle.encrypt(
    { name: ALG, iv },
    key,
    new TextEncoder().encode(plain),
  );
  return `${bytesToBase64(iv)}:${bytesToBase64(new Uint8Array(ciphertext))}`;
}

export async function decryptCredentials(enc: string, keyHex: string): Promise<string> {
  if (keyHex.length !== 64) {
    throw new Error('encryption key must be 32 bytes (64 hex chars)');
  }
  const [ivB64, dataB64] = enc.split(':');
  if (!ivB64 || !dataB64) {
    throw new Error('malformed credentials envelope (expected iv:ciphertext)');
  }
  const key = await importKey(keyHex, ['decrypt']);
  const plaintext = await crypto.subtle.decrypt(
    { name: ALG, iv: base64ToBytes(ivB64) },
    key,
    base64ToBytes(dataB64),
  );
  return new TextDecoder().decode(plaintext);
}

async function importKey(keyHex: string, usages: KeyUsage[]): Promise<CryptoKey> {
  return crypto.subtle.importKey('raw', hexToBytes(keyHex), ALG, false, usages);
}

function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary);
}

function base64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}
