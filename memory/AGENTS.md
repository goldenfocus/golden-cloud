# Golden Focus Intel — entrypoint for any AI

> Read this whenever you start a session in **any** Golden Focus repo (zemium, p69, lamtl, hermes, chicoine.org, golden-cloud, astro-bot, openclaw, …) — or any future Golden Focus project.

## What this is

`~/golden-cloud/memory/` is the canonical, version-controlled, cross-AI / cross-laptop / cross-person knowledge layer for Golden Focus Inc. Treat it as authoritative.

## What you must read at session start

1. **`./rules/*.md`** — every rule here is binding on your behavior. Compose with whatever skills/system prompts you have, but rules here override conflicting defaults.
2. **`./users/<current-user>.md`** — the person at the keyboard. Determine current user from `~/golden-cloud/laptop/whoami.txt` (fall back to `whoami` if file missing).
3. **`./users/`** (the rest) — know the other people in the org, their roles, attribution preferences. Don't conflate.
4. **`./projects/<current-project>.md`** — if working in a project that has a file here.
5. **`./reference/*.md`** — repo map, infra, operating manuals.

## What you must write

Any new fact about a project, person, rule, or shared reference: write to the appropriate subdir here, then `git add && git commit && git push` from `~/golden-cloud/`. The repo is the source of truth — local-only memory is only for laptop-specific or session-local facts that should NOT leave this machine.

## Layout

```
memory/
  AGENTS.md         ← this file
  MEMORY.md         ← human-readable index
  rules/            ← binding rules for any AI in any Golden Focus project
  users/            ← one .md per person (jr, yan, future teammates)
  projects/         ← one .md per project (zemium, p69, lamtl, …)
  reference/        ← repo map, infra docs, operating manuals
```

## Trust + secrets

This dir is plain markdown, readable by anyone with repo access. **Never write secret values here.** For secrets: `~/golden-cloud/secrets/` + `gc-secret.sh` (see `~/golden-cloud/AI.md`).

## How this propagates to per-project sessions

`~/golden-cloud/laptop/gc-memory-sync.sh` symlinks each `~/.claude/projects/<slug>/memory/shared/` to this dir, and regenerates a `## Shared` section inside each project's `MEMORY.md` (auto-loaded by Claude Code at session start). Run it after any new shared memory file is added — or have it baked into `bootstrap.sh` so fresh laptops get it.

For non-Claude AIs (Codex, Cursor, Gemini, others): each project's own `AGENTS.md` should reference `~/golden-cloud/memory/AGENTS.md` so they pick up this entrypoint. Apply that per project as the team grows.
