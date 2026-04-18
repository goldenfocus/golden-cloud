# Global CLAUDE.md — The Soul

> Rules for every session. Non-negotiable. Every rule with an **Incident:** tag is scar tissue — treat it like gospel.

---

## The Prime Directive

Build amazing products at lightspeed. The user's mental bandwidth is for taste, strategy, and delight — not tooling, syntax, or permission-asking. Your job is to compress the distance from idea to running-in-prod.

But: **the user controls the deploy button. Always.** Speed with a safety rail, not speed without one.

---

## Git — Worktrees + Never Push Without Permission

> 🚨 **HARD RULE: NEVER run `git push` unless the user explicitly says "push it", "deploy", "ship it", or invokes the `/push` skill. Exception: prod is actively down — see `feedback_push_when_prod_down`.**

Multiple sessions run concurrently. Every push = a Vercel prod build (paid minutes, potential double-deploy).

**Session start — always:**
```bash
git fetch origin main
git worktree add .claude/worktrees/<short-name> -b <short-name> origin/main
cd .claude/worktrees/<short-name>
```

If working from the main checkout, `git pull origin main` first. **Incident (Mar 10 2026):** notification-worker deployed from stale local main — missing file broke push notifications for 2 minutes.

**When work is done:** commit → build → report → **STOP**. Wait for the human.

**When the user says push:** fetch → rebase origin/main → build once more → `git push origin HEAD:main` → `/smoke-test` → verify migrations.

**After push:** clean up worktree + local branch. No orphans.

Rules:
- `main` is the only remote branch. Push to `main` via `git push origin HEAD:main`. No feature branches on remote.
- Never force push to main. Resolve rebase conflicts.
- Never manually apply migrations to prod — CI runs `supabase db push`. Only intervene if CI finished AND the migration is confirmed missing from `schema_migrations`.

---

## Use Skills And Agents Proactively

The user should never have to remember which tool to invoke. If a skill or agent matches, use it without asking.

**Workflow skills (use reflexively):**
- `/triage` — any bug report or screenshot. No clarifying questions first.
- `/migrate` — every migration file. Collision-proof timestamps.
- `/smoke-test` — after every user-authorized push.
- `/ops` — any data/business question ("how many…", "top…", "which user…").
- `/push` — when the user authorizes deploy.
- `/sync-universe` — after significant feature work.

**Superpowers skills (use per their triggers):**
- `brainstorming` — before any creative/design work.
- `writing-plans` / `executing-plans` — for multi-step tasks.
- `verification-before-completion` — before claiming "done", "fixed", or "passing". Evidence before assertions.
- `test-driven-development` — before writing implementation code.
- `systematic-debugging` — for any bug or unexpected behavior.
- `using-git-worktrees` — starting isolated feature work.
- `dispatching-parallel-agents` — when 2+ independent tasks have no shared state.

**Domain agents (spawn automatically on their triggers):**
- `qa-gatekeeper` — binary SHIP/HOLD before auto-merge or push.
- `preview-verifier` — verify preview URL fix + neighbors, Playwright.
- `post-deploy-verifier` — after prod deploy, with auto-revert authority.
- `premium-ux-auditor` — after any user-facing component change, or when user says "doesn't feel premium".
- `data-integrity-checker` — suspicious data inconsistency.
- `cron-monitor` — when checking if automations are running.

**Parallelism is default when tasks are independent.** Multiple Grep/Glob/Read in one message. Multiple agents in one message when they don't share state. Don't serialize work out of habit.

---

## Routines & Auto-Merge Policy

Routines (scheduled agents) may **auto-merge fixes** to main only after passing `qa-gatekeeper` → Vercel preview → `preview-verifier` → `post-deploy-verifier`. Full pipeline or nothing.

**Tiered kill switch — canonical list lives in `.claude/agents/qa-gatekeeper.md`.** Summary:
- **Tier A:** migrations, RLS, `calculate_*`/`*_commission*`/`*_payout*`, financial triggers, constraint changes, CI/CD config, CLAUDE.md, Sentry config → **always HOLD, ping user**
- **Tier B:** TypeScript under `bookings/`, `vouchers/`, `wallet/`, `shifts/`, `cashflow/`, `credit*/` → **HOLD in Phase 1 (2-week trial), auto-merge in Phase 2+**
- **Tier C:** everything else → **auto-merge from day one if gauntlet passes**

Routines post updates to **one notification surface** — Telegram. Three daily briefings (3am/9am/6pm ET) using the Post-Deploy Summary format below. One place, zero tab-scrolling.

---

## Pre-Push QA — The Gauntlet

Before any push (human-triggered or routine):
- **Build** must pass (`pnpm build` or `bash scripts/safe-build.sh`) with zero new warnings.
- **Code Reviewer** and **Silent Failure Hunter** agents run in parallel on the diff.
- **i18n validator** (`pnpm check-i18n`) passes.
- Use `superpowers:verification-before-completion` before claiming green.

All must pass. If anything flags, fix and re-run — don't bypass.

---

## Post-Deploy Summary — Always Required

After every push, output exactly this format. Routines use the same format. One message, one place, zero mental overhead.

```
🚀 Deployed: <one-line description>

What changed:
- <file or area>: <what and why>

Test on <site>:
1. Go to <url>
2. <specific action>
3. <exact expected outcome>
```

Max 5 bullets, max 3 test steps. Specific enough to verify in 60 seconds cold.

---

## Writing & Copy — The Vibe

- **Smart, cheeky, spark joy** — never corporate, never bland
- Warm + confident, a touch of playfulness, cringe forbidden
- Premium feel without pretension
- Tiebreaker: "Would reading this make someone smile?"

---

## The Four Buyer Types — No Buyer Left Behind

Every customer-facing piece addresses all four:

| Type | Their Question | How We Answer |
|------|---------------|---------------|
| **Competitive** | "What's in it for me?" | Benefits, results, value |
| **Methodical** | "How does it work?" | Process, transparency, detail |
| **Humanistic** | "Who else does that?" | Social proof, reviews, community |
| **Spontaneous** | "Why should I act now?" | Urgency, excitement, exclusivity |

---

## i18n — Zero Hardcoded Text

Every user-facing string goes through the project's translation system. No exceptions. If you add copy, you add it to every locale.

---

## Engine Optimization — Always Be Discoverable

Every page and technical decision considers all engine types:

| Engine | Means | How We Optimize |
|--------|-------|-----------------|
| **SEO** | Google, Bing | Semantic HTML, meta, structured data, sitemaps, fast CWV |
| **AEO** | Featured snippets, voice | FAQ schema, concise Q&A, direct answers in headings |
| **AIO** | ChatGPT/Perplexity/Claude | `llms.txt`, clean structure, authoritative + cite-worthy |
| **GEO** | AI-generated overviews | Unique perspectives, quotable stats, expert depth |
| **LEO** | Maps, "near me" | NAP consistency, Google Business Profile, local schema |
| **VEO** | YouTube, Google Images | Alt text, image schema, transcripts, descriptive filenames |

**Defaults:** every page has title/meta/OG/canonical + JSON-LD (Organization/LocalBusiness/WebPage minimum). Images always have descriptive `alt` + optimized filenames. `llms.txt` + `llms-full.txt` maintained.

---

## Supabase Migrations — Verify or Die

**Incident (Mar 4 2026):** version collision silently skipped the `room_ai_columns` migration — room verification broke for hours with no visible errors until someone hit the broken path.

- p69 CI auto-applies migrations via `supabase db push` in GitHub Actions.
- **After every push with a migration, VERIFY it applied:**
  ```bash
  echo "SELECT version, name FROM supabase_migrations.schema_migrations ORDER BY version DESC LIMIT 5;" > /tmp/check.sql
  ./scripts/supabase-run-sql.sh /tmp/check.sql
  ```
- **Do not end the session until confirmed.** A silently-skipped migration = prod referencing columns that don't exist.
- If skipped: rename file to a unique timestamp, apply SQL manually, push again.
- p69 and lamtl share `lsfuigfgfvybswfjimww`. Before dropping any DB object, grep BOTH `/Users/vibeyang/p69/` AND `/Users/vibeyang/lamtl/`.
- `psql` at `/opt/homebrew/opt/libpq/bin/psql`.

---

## Screenshot = Source of Truth

When the user shares a screenshot:
- Identify the component file from the visible UI within 30 seconds.
- Do NOT ask "can you reproduce it?" — they already see it.
- Name at least one specific file path before asking any questions.

---

## General Principles

- Read code before modifying it.
- Prefer editing existing files to creating new ones.
- No over-engineering. No speculative abstractions.
- Commits: concise, prefixed (`feat:`, `fix:`, `refactor:`, `chore:`).
- **If a skill exists, use it.** Don't reinvent workflows.
- **If a decision is reversible and local, just do it.** Ask only for high-blast-radius actions (push, force-push, destructive DB ops, PR comments, external messages).
- **When in doubt, ship less.** One logical change per commit. Especially on the money path.

---

## Instruction Priority

When instructions conflict:
1. User's explicit message (this conversation)
2. Project CLAUDE.md (repo-specific)
3. This global CLAUDE.md
4. Superpowers skills
5. Default system behavior

Lower overrides higher only when the higher says to defer.
