// Eval harness: POSTs each question to a live guide endpoint and scores first-round tool choice.
// Usage: GUIDE_ENDPOINT=http://localhost:3000/api/guide npx tsx tests/eval/run-eval.ts
// Not run in CI (needs a live brain). Pass threshold: >= 80%.
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

interface EvalCase {
  q: string;
  expectTools: string[];
}

const endpoint = process.env.GUIDE_ENDPOINT ?? 'http://localhost:3000/api/guide';
const cases: EvalCase[] = JSON.parse(
  readFileSync(join(dirname(fileURLToPath(import.meta.url)), 'questions.json'), 'utf8')
);

const snapshot = { route: '/', elements: [] };
let passed = 0;

for (const c of cases) {
  const res = await fetch(endpoint, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ messages: [{ role: 'user', content: c.q }], snapshot }),
  });
  const data = (await res.json()) as { message: string; toolCalls: Array<{ name: string }> };
  const got = data.toolCalls.map((t) => t.name);
  const ok =
    c.expectTools.length === 0 ? got.length === 0 : c.expectTools.every((t) => got.includes(t));
  if (ok) passed++;
  console.log(
    `${ok ? '✅' : '❌'} "${c.q}" → [${got.join(', ')}] (expected [${c.expectTools.join(', ')}])`
  );
}

const pct = Math.round((passed / cases.length) * 100);
console.log(`\n${passed}/${cases.length} passed (${pct}%) — threshold 80%`);
process.exit(pct >= 80 ? 0 : 1);
