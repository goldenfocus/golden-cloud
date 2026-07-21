# golden-guide

> An embeddable AI support agent that **drives** your web app — it doesn't tell users where
> things are, it takes them there. Navigate, highlight, scripted guided flows, and one-tap
> escalation to a human. ElevenLabs-support-agent vibes, zero vendor lock-in.

## What it does

A chat bubble any Next.js App Router app can vendor in. The agent can:

- **`run_flow`** — execute an authored, deterministic guided flow (navigate → highlight →
  narrate). The model's main job is *selecting* the right flow, which small models do reliably.
- **`navigate_to`** — route the app to an allowlisted path.
- **`highlight`** — scroll to an element tagged `data-agent-id` and pulse a glow around it.
- **`escalate_to_support`** — send the transcript to your Telegram, rate-capped.
- Answer questions grounded ONLY in a markdown knowledge base you inline at config time.

Architecture: stateless server route (`createGuideHandler`) → any OpenAI-compatible brain →
validated tool calls → executed by the browser widget. No WebSocket, no session store.

## When to use

- Any Next.js app where "how do I…?" is better answered by *showing*.
- You want support that costs ~cents/month (flows keep model calls tiny).
- You want the brain swappable (hosted API in prod, Ollama locally) via env vars.

## When NOT to use

- You need form-filling or submission by the agent — v1 deliberately excludes it (the agent
  can never submit, confirm, delete, or pay).
- You need voice I/O (not in v1).
- Non-Next.js hosts (the core is framework-light, but the wiring here targets App Router).
- **Never point a public deployment at a local box carrying other production duties.**
  Local brains (Ollama) are for dev/experiments only.

## Install (copy-in)

1. Vendor the code: `cp -R blocks/golden-guide/src/. <your-app>/lib/golden-guide/`
2. Mount the route: copy `examples/next/route.example.ts` → `app/api/guide/route.ts`
3. Write your config (`lib/guide/config.ts` — routes allowlist, flows, voice) and KB
   (`lib/guide/kb.ts`), see `examples/next/guide.config.example.ts`
4. Mount the widget in your layout via a small client wrapper that passes `router.push`
5. Tag guide targets: `<button data-agent-id="record-start">…</button>`

## Brain config (env)

| Var | Default | Notes |
|---|---|---|
| `GUIDE_BRAIN_BASE_URL` | `https://api.openai.com/v1` | Any OpenAI-compatible endpoint. Ollama dev: `http://localhost:11434/v1` |
| `GUIDE_BRAIN_API_KEY` | falls back to `OPENAI_API_KEY` | |
| `GUIDE_BRAIN_MODEL` | `gpt-4o-mini` | Ollama dev: `qwen3:8b` |
| `GUIDE_DISABLED` | unset | `1` = kill switch (friendly "guide is resting" reply) |

No daily token budget in v1 — use `GUIDE_DISABLED` as the manual kill switch; per-request
caps + rate limits bound the per-minute burn.

## Security model

- Server owns the system prompt; client-supplied `system` roles are **rejected** (400).
- Tool allowlists are enforced server-side AND baked into tool schemas as enums.
- `highlight` only accepts agent-ids present in the *current* page snapshot.
- Tool-call IDs are HMAC-signed; forged `tool_result`s are rejected (stateless anti-forgery).
- Hard cap of 4 tool rounds per user turn; per-IP rate limiting; input size caps.
- Page snapshot and user text are delimited as untrusted data in the prompt.
- The agent can never submit, confirm, delete, or pay — humans click.

## Testing

- `npm test` — 29 unit/contract tests (validation sandbox, anti-forgery, limits, executor).
- `npm run typecheck`
- **Eval harness** (the brain gate): with your app running locally,
  `GUIDE_ENDPOINT=http://localhost:3000/api/guide npx tsx tests/eval/run-eval.ts`
  Threshold ≥ 80% — run it before swapping brains or editing the prompt/flows.

## Design docs

- Spec: `docs/superpowers/specs/2026-07-21-golden-guide-design.md`
- Plan: `docs/superpowers/plans/2026-07-21-golden-guide.md`

First production host: [ezviet.org](https://ezviet.org).
