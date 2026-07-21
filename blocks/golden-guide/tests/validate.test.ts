import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateToolCall } from '../src/server/validate';
import type { GuideConfig, PageSnapshot } from '../src/shared/types';

const config = {
  routes: [{ path: '/karaoke', description: 'karaoke' }],
  flows: [{ id: 'tour', title: 'Tour', triggers: [], steps: [{ say: 'hi' }] }],
} as unknown as GuideConfig;
const snapshot: PageSnapshot = {
  route: '/',
  elements: [{ id: 'record-button', tag: 'button', label: 'Record' }],
};

test('navigate_to: allowlisted path passes, others rejected', () => {
  assert.equal(validateToolCall({ name: 'navigate_to', args: { path: '/karaoke' } }, config, snapshot).ok, true);
  assert.equal(validateToolCall({ name: 'navigate_to', args: { path: '/admin' } }, config, snapshot).ok, false);
  assert.equal(validateToolCall({ name: 'navigate_to', args: { path: 'https://evil.com' } }, config, snapshot).ok, false);
});

test('highlight: only agent-ids present in the snapshot', () => {
  assert.equal(validateToolCall({ name: 'highlight', args: { agentId: 'record-button' } }, config, snapshot).ok, true);
  assert.equal(validateToolCall({ name: 'highlight', args: { agentId: 'hallucinated' } }, config, snapshot).ok, false);
});

test('run_flow: only configured flow ids', () => {
  assert.equal(validateToolCall({ name: 'run_flow', args: { flowId: 'tour' } }, config, snapshot).ok, true);
  assert.equal(validateToolCall({ name: 'run_flow', args: { flowId: 'nope' } }, config, snapshot).ok, false);
});

test('unknown tools and non-string args rejected', () => {
  assert.equal(validateToolCall({ name: 'set_input', args: {} }, config, snapshot).ok, false);
  assert.equal(validateToolCall({ name: 'navigate_to', args: { path: 42 } }, config, snapshot).ok, false);
});

test('escalate_to_support passes with string reason', () => {
  const r = validateToolCall({ name: 'escalate_to_support', args: { reason: 'stuck' } }, config, snapshot);
  assert.equal(r.ok, true);
});
