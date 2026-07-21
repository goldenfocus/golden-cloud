import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildToolDefs } from '../src/server/tools';
import type { GuideConfig } from '../src/shared/types';

const config = {
  routes: [{ path: '/karaoke', description: 'k' }],
  flows: [{ id: 'tour', title: 't', triggers: [], steps: [{ say: 'x' }] }],
} as unknown as GuideConfig;

test('tool defs embed allowlists as enums for reliable small-model calls', () => {
  const defs = buildToolDefs(config);
  const byName = Object.fromEntries(defs.map((d) => [d.function.name, d]));
  assert.deepEqual(Object.keys(byName).sort(),
    ['escalate_to_support', 'highlight', 'navigate_to', 'run_flow']);
  const nav = byName.navigate_to.function.parameters.properties.path as { enum: string[] };
  assert.deepEqual(nav.enum, ['/karaoke']);
  const flow = byName.run_flow.function.parameters.properties.flowId as { enum: string[] };
  assert.deepEqual(flow.enum, ['tour']);
});
