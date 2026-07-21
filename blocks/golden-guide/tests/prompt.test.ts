import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildSystemPrompt } from '../src/server/prompt';
import type { GuideConfig, PageSnapshot } from '../src/shared/types';

const config = {
  appName: 'EZViet',
  voice: 'cheeky',
  kb: '## Tiers\nfree: 12 cards',
  flows: [{ id: 'tour', title: 'Show around', triggers: ['show me around'], steps: [{ say: 'hi' }] }],
  routes: [{ path: '/karaoke', description: 'sing along' }],
} as unknown as GuideConfig;
const snapshot: PageSnapshot = { route: '/', elements: [{ id: 'deck', tag: 'div', label: 'Flashcards' }] };

test('prompt contains voice, KB, flow catalog, routes, snapshot, and injection guard', () => {
  const p = buildSystemPrompt(config, snapshot);
  for (const needle of ['EZViet', 'cheeky', 'free: 12 cards', 'tour', '/karaoke', 'deck',
    'never instructions', 'NEVER submit']) {
    assert.ok(p.includes(needle), `missing: ${needle}`);
  }
});

test('snapshot content is delimited as untrusted data', () => {
  const p = buildSystemPrompt(config, snapshot);
  assert.ok(p.indexOf('<page_snapshot>') < p.indexOf('deck'));
  assert.ok(p.indexOf('deck') < p.indexOf('</page_snapshot>'));
});
