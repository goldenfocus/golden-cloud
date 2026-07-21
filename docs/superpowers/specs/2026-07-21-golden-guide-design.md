# golden-guide — Design Spec

> **Date:** 2026-07-21 · **Status:** Approved (Yan, 2026-07-21 "Alright let's go!")
> An embeddable AI support agent that *drives* the host web app — navigates, highlights,
> guides — like the ElevenLabs support agent, as a reusable Golden Block.

## 1. Purpose

A chat widget any goldenfocus Next.js app can vendor in that:

- Answers support questions grounded in the app's knowledge base
- **Shows instead of tells**: navigates to the right page and highlights the right element,
  narrating as it goes ("Let me show you")
- Escalates to a human (Telegram) when it can't help
- Costs ~cents/month to run and swaps brains via config

Pilot host: **ezviet.org**.

## 2. Decisions already made (with rationale)

| Decision | Rationale |
|---|---|
| **Own agent loop**, not ElevenLabs platform | No vendor lock-in per app; brain is swappable; no WebSocket infra needed |
| **Brain = any OpenAI-compatible chat-completions endpoint** via config | One `baseURL`/`apiKey`/`model` config covers hosted APIs and Ollama |
| **Prod default = hosted cheap model with hard caps** | Red-team kill #1: the available local box already runs other load-sensitive production workloads; a public unauthenticated endpoint must never be wired to it. Flows-as-router makes calls tiny → hosted cost ≈ cents/month |
| **Mac mini/Ollama = dev/experiment brain only** | Same config shape; just never pointed at by a public deployment |
| **Flows-as-router** is the primary unit | Small models reliably *select* a flow; they unreliably improvise multi-step DOM driving. Moves reliability from demo to shippable |
| **v1 cuts `set_input`** | Most fragile tool (React 19 controlled inputs need native-setter tricks); not in Yan's actual ask. v1.1 candidate with `Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set` approach documented |
| **v1 cuts `kb_search` tool; KB is inlined into the system prompt** | App help content is a few KB of markdown; full-KB-in-context beats small-model query composition; deletes a tool, a round-trip, and a failure mode |
| **Voice: out of scope v1** | Text chat first; architecture doesn't preclude it |

## 3. Architecture

```
Browser                              Host app (Vercel)                Brain
┌─────────────────────┐   POST /api/guide   ┌──────────────────┐   ┌─────────────────┐
│ <GuideWidget />     │ ───────────────────▶│ createGuideHandler│──▶│ OpenAI-compatible│
│  - chat UI          │ ◀─────────────────── │  - system prompt  │   │ endpoint         │
│  - page snapshot    │  assistant text +    │  - KB inline      │   │ (hosted / Ollama)│
│  - client tool exec │  client tool calls   │  - flow catalog   │   └─────────────────┘
│    navigate/highlight│                     │  - validation     │
│    /run_flow        │                      │  - rate limits    │──▶ Telegram (escalate)
└─────────────────────┘                      └──────────────────┘
```

- **Stateless server.** The browser holds display history and POSTs it each turn. The server
  treats the client array as untrusted display text only (see §6).
- **Loop shape:** server calls the brain; if the brain emits client tools, the server validates
  them and returns them; the browser executes and POSTs tool results to continue.
  Hard cap: **4 tool iterations per user turn**, then forced text answer or escalation.

## 4. Components

### 4.1 Server — `createGuideHandler(config)`

Route-handler factory mounted at `app/api/guide/route.ts`. Config:

```ts
interface GuideConfig {
  brain: { baseURL: string; apiKey?: string; model: string };
  appName: string;
  voice: string;              // brand voice, e.g. "smart, cheeky, spark joy"
  kb: string;                 // markdown, inlined into system prompt (built at import time)
  flows: GuideFlow[];
  routes: RouteEntry[];       // navigate_to allowlist: { path, description }
  escalate?: { telegramBotToken: string; chatId: string };
  limits?: { maxToolIterations?: number; maxInputTokens?: number;
             maxMessages?: number; dailyTokenBudget?: number };
}
```

Responsibilities: build system prompt (persona + voice + KB + flow catalog + page snapshot,
untrusted data clearly delimited); strip client `system` roles; validate all tool calls
(names, schemas, route allowlist, agent-id existence in snapshot); iteration cap; per-IP
rate limiting; daily token budget kill-switch; execute `escalate_to_support` server-side.

### 4.2 Client — `<GuideWidget />` + executor

- Chat bubble, Tailwind only, works at 375px, **all text inputs ≥ 16px** (iOS zoom rule)
- Collects a **page snapshot** each user turn: current route + all `[data-agent-id]`
  elements (id, tag, label/text, role), **capped at ~800 tokens** (tested ceiling)
- Client tools:
  - `navigate_to(path)` — `next/navigation` router push; path must be in the allowlist
  - `highlight(agentId)` — `scrollIntoView` + temporary glow CSS animation; only elements
    bearing `data-agent-id`; reports "not found" back as tool result instead of faking success
  - `run_flow(flowId)` — executes a flow's steps client-side with per-step narration
- First-open **"Show me around"** chip → runs the tour flow (zero typing to the wow)

### 4.3 Flows

```ts
interface GuideFlow {
  id: string;
  title: string;              // shown to model for selection
  triggers: string[];         // example user phrasings
  steps: Array<
    | { navigate: string; say: string }
    | { highlight: string; say: string }   // agent-id
    | { say: string }
  >;
}
```

The model's main job is **selecting** a flow and paraphrasing `say` lines in the app's voice.
Free-form navigate/highlight remain available for questions no flow covers.

### 4.4 DOM contract

Interactive elements opt in via `data-agent-id="voice-record-button"` — stable, kebab-case,
human-meaningful. Only opted-in elements are drivable. (Accessibility-tree auto-snapshot is a
v2 upgrade; `data-agent-id` stays the override.)

### 4.5 Escalation

`escalate_to_support` (server tool): sends transcript to Telegram. Caps: 3/session, 1/min,
deduped, transcript truncated, link previews disabled. Unanswerable questions (no flow, no KB
hit, model punts) log to the same channel — free product-research backlog.

## 5. Tool schemas (v1)

| Tool | Side | Args | Guard |
|---|---|---|---|
| `navigate_to` | client | `{ path }` | path ∈ `config.routes` allowlist |
| `highlight` | client | `{ agentId, say? }` | agentId ∈ current page snapshot |
| `run_flow` | client | `{ flowId }` | flowId ∈ `config.flows` |
| `escalate_to_support` | server | `{ reason }` | rate caps §4.5 |

Explicitly **not** in v1: `set_input`, form submission of any kind, `kb_search`.
The agent can never submit, confirm, delete, or pay — a human click is always required.

## 6. Security invariants (red-team driven)

1. **Never wire a public deployment to a local box that carries other production duties.** Local brains are dev-only.
2. Server owns the system prompt; client-supplied `system` messages are discarded;
   tool list is re-derived server-side every request.
3. All snapshot/KB/history text is wrapped in delimited untrusted-data blocks — data, not
   instructions.
4. Every tool call validated against schema + allowlist before leaving the server; invalid
   calls are reported to the model as errors, never forwarded.
5. Per-IP + per-session rate limits; max messages and input tokens per request; daily token
   budget with automatic kill-switch (returns a friendly "guide is resting" message).
6. Tool-call IDs are minted server-side per turn; a `tool` result whose ID wasn't just minted
   is rejected (anti-forgery).
7. KB is inlined at build/import time — the model never names a file path; no fs access from
   model-supplied strings.
8. Escalation caps per §4.5; transcripts sanitized.

## 7. Testing (eng-rigor driven)

- **Eval harness** (`tests/eval/`): ~20 real questions with expected tool-call sequences,
  runnable against any configured brain; pass threshold ≥ 80% gates brain choice and every
  prompt/snapshot change. Ships with the block.
- **Allowlist contract tests**: adversarial model outputs (bad tool names, off-allowlist
  routes, hallucinated agent-ids, forged tool-result IDs, client `system` injection) must all
  be rejected — proves the tool layer is the sandbox.
- **Snapshot budget test**: heaviest pilot page snapshot ≤ 800 tokens.
- Unit tests for flow execution, highlight fallback, iteration cap.

## 8. Packaging — Golden Block

```
~/golden-cloud/blocks/golden-guide/
  README.md        # what/why/when/when-NOT; install steps; security notes
  block.json       # manifest, VERSION field
  src/             # copy-in TypeScript: server/, client/, shared/ (schemas, types)
  tests/           # eval harness + contract tests (Node test runner)
  examples/        # minimal Next.js wiring: route.ts + layout snippet + guide.config.ts
```

Copy-in vendoring with a `VERSION` constant in `src/` so drift is detectable; security-default
config (rate limits on, allowlists required, no default brain URL). Footer credit
"Guided by golden-guide" links back to the block (distribution).

## 9. Pilot — ezviet

- Mount handler at `app/api/guide/route.ts`; widget in root layout (client component)
- `data-agent-id` on ~10 key elements (record button, karaoke controls, deck, pricing CTA…)
- 3 authored flows: "record my voice", "how karaoke sync works", "daily card limit / tiers"
- Tour flow for the "Show me around" chip
- KB: one markdown file distilled from existing ezviet docs/UX
- Brain: hosted cheap model (env-configured), caps on; Ollama config documented for dev
- ezviet is Tier C surface (no money path) — normal dev task after block lands

## 10. Out of scope (v1)

Voice I/O · `set_input` / form filling · embeddings/RAG · accessibility-tree auto-snapshot ·
npm packaging · non-Next.js hosts (block core kept framework-light for later adapters)

## 11. Rollback levers (named, per skip-question-take-lean)

- "**roll back to local-in-prod**" — point a public app at Ollama (requires a separate box,
  not the golden-cams mini; caveats documented)
- "**bring back set_input**" — v1.1 with React-19 native-setter implementation
- "**bring back kb_search**" — if an app's KB outgrows the prompt budget
