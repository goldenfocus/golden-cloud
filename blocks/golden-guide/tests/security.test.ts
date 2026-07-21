import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mintCallId, verifyCallId, deriveSecret } from '../src/server/security';

test('minted callId verifies for same name+secret', () => {
  const id = mintCallId('highlight', 's3cret');
  assert.equal(verifyCallId(id, 'highlight', 's3cret'), true);
});

test('verification fails for wrong name, wrong secret, or garbage', () => {
  const id = mintCallId('highlight', 's3cret');
  assert.equal(verifyCallId(id, 'navigate_to', 's3cret'), false);
  assert.equal(verifyCallId(id, 'highlight', 'other'), false);
  assert.equal(verifyCallId('forged', 'highlight', 's3cret'), false);
  assert.equal(verifyCallId('a.b', 'highlight', 's3cret'), false);
});

test('deriveSecret is deterministic and non-trivial', () => {
  assert.equal(deriveSecret('k'), deriveSecret('k'));
  assert.notEqual(deriveSecret('k'), deriveSecret('k2'));
  assert.ok(deriveSecret('k').length >= 32);
});
