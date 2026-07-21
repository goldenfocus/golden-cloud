import { test } from 'node:test';
import assert from 'node:assert/strict';
import { executeToolCall } from '../src/client/executor';
import { makeDoc, makeElement } from './helpers/fake-dom';
import type { GuideFlow } from '../src/shared/types';

const noWait = () => Promise.resolve();

test('navigate_to calls the router', async () => {
  const visited: string[] = [];
  const result = await executeToolCall(
    { callId: 'a.b', name: 'navigate_to', args: { path: '/karaoke' } },
    [],
    { navigate: (p) => visited.push(p), doc: makeDoc([]), onSay: () => {}, wait: noWait }
  );
  assert.deepEqual(visited, ['/karaoke']);
  assert.ok(result.includes('/karaoke'));
});

test('highlight scrolls, glows, and reports not-found honestly', async () => {
  const el = makeElement('button', { 'data-agent-id': 'record-button' }, 'Rec');
  const doc = makeDoc([el]);
  const deps = { navigate: () => {}, doc, onSay: () => {}, wait: noWait };
  const ok = await executeToolCall(
    { callId: 'a.b', name: 'highlight', args: { agentId: 'record-button' } },
    [],
    deps
  );
  assert.ok(ok.includes('highlighted'));
  assert.equal(el.scrolled, true);
  assert.equal(el.classList.has('gg-glow'), true);
  const missing = await executeToolCall(
    { callId: 'a.b', name: 'highlight', args: { agentId: 'nope' } },
    [],
    deps
  );
  assert.ok(missing.includes('not found'));
});

test('run_flow executes steps in order with narration', async () => {
  const flow: GuideFlow = {
    id: 'tour',
    title: 'Tour',
    triggers: [],
    steps: [
      { say: 'Welcome!' },
      { navigate: '/karaoke', say: 'Here is karaoke.' },
      { highlight: 'song-list', say: 'Pick a song.' },
    ],
  };
  const said: string[] = [];
  const visited: string[] = [];
  const doc = makeDoc([makeElement('div', { 'data-agent-id': 'song-list' }, 'Songs')]);
  const result = await executeToolCall(
    { callId: 'a.b', name: 'run_flow', args: { flowId: 'tour' } },
    [flow],
    { navigate: (p) => visited.push(p), doc, onSay: (t) => said.push(t), wait: noWait }
  );
  assert.deepEqual(said, ['Welcome!', 'Here is karaoke.', 'Pick a song.']);
  assert.deepEqual(visited, ['/karaoke']);
  assert.ok(result.includes('completed'));
});

test('unknown flow and unknown tool report errors as strings', async () => {
  const deps = { navigate: () => {}, doc: makeDoc([]), onSay: () => {}, wait: noWait };
  const r1 = await executeToolCall({ callId: 'a.b', name: 'run_flow', args: { flowId: 'x' } }, [], deps);
  assert.ok(r1.includes('not found'));
  const r2 = await executeToolCall({ callId: 'a.b', name: 'mystery', args: {} }, [], deps);
  assert.ok(r2.includes('unknown tool'));
});
