import { test } from 'node:test';
import assert from 'node:assert/strict';
import { collectSnapshot } from '../src/client/snapshot';
import { makeDoc, makeElement } from './helpers/fake-dom';

test('collects agent-id elements with trimmed labels', () => {
  const doc = makeDoc([
    makeElement('button', { 'data-agent-id': 'record-button' }, '  Record\n  your voice  '),
    makeElement('a', { 'data-agent-id': 'nav-karaoke', 'aria-label': 'Karaoke' }, 'ignored'),
  ]);
  const snap = collectSnapshot(doc, '/record');
  assert.equal(snap.route, '/record');
  assert.deepEqual(snap.elements, [
    { id: 'record-button', tag: 'button', label: 'Record your voice' },
    { id: 'nav-karaoke', tag: 'a', label: 'Karaoke' },
  ]);
});

test('truncates to the char budget (~800 tokens)', () => {
  const many = Array.from({ length: 200 }, (_, i) =>
    makeElement('button', { 'data-agent-id': `id-${i}` }, 'x'.repeat(60))
  );
  const snap = collectSnapshot(makeDoc(many), '/');
  const used = snap.elements.reduce((n, e) => n + e.id.length + e.tag.length + e.label.length + 8, 0);
  assert.ok(used <= 3200, `budget exceeded: ${used}`);
  assert.ok(snap.elements.length < 200);
});
