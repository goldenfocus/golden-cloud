import { test } from 'node:test';
import assert from 'node:assert/strict';
import { RateLimiter, countToolRounds, totalChars } from '../src/server/limits';
import type { WireMessage } from '../src/shared/types';

test('RateLimiter: allows up to max within window, then blocks, then recovers', () => {
  const rl = new RateLimiter(2, 1000);
  assert.equal(rl.allow('ip', 0), true);
  assert.equal(rl.allow('ip', 10), true);
  assert.equal(rl.allow('ip', 20), false);
  assert.equal(rl.allow('other', 20), true); // independent keys
  assert.equal(rl.allow('ip', 1500), true); // window expired
});

test('countToolRounds: counts assistant tool rounds since last user message', () => {
  const messages: WireMessage[] = [
    { role: 'user', content: 'q1' },
    { role: 'assistant', content: '', toolCalls: [{ callId: 'a.b', name: 'navigate_to', args: { path: '/x' } }] },
    { role: 'tool_result', callId: 'a.b', name: 'navigate_to', result: 'ok' },
    { role: 'user', content: 'q2' },
    { role: 'assistant', content: '', toolCalls: [{ callId: 'c.d', name: 'highlight', args: { agentId: 'x' } }] },
    { role: 'tool_result', callId: 'c.d', name: 'highlight', result: 'ok' },
  ];
  assert.equal(countToolRounds(messages), 1); // only the round after q2
});

test('totalChars sums content and results', () => {
  const messages: WireMessage[] = [
    { role: 'user', content: 'abc' },
    { role: 'tool_result', callId: 'x.y', name: 'highlight', result: 'de' },
  ];
  assert.equal(totalChars(messages), 5);
});
