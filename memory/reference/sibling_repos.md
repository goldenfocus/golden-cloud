---
name: Golden Focus sibling repo map (~/)
description: What each repo in ~/ does, which ones host reusable infra, and where prior work lives
type: reference
---

`/Users/theoutsider/` (and yan's equivalent) hosts the full Golden Focus portfolio. Before designing any subsystem, grep these dirs for existing implementations. **Reuse over rebuild — that's literally the "golden blocks" thesis** (yan's framing, executed by JR).

## Core infra

- `golden-cloud/` — yan's shared-brain repo: cross-AI/cross-laptop secrets (SOPS+age via `gc-secret.sh`), prompts, notes, plans, blocks, **shared AI memory** (this dir's parent). Operating manual: `~/golden-cloud/AI.md`. Both yan and JR depend on it.
- `golden-cloud-public/` — public-shareable counterpart (parallel structure). May not exist yet on every laptop.

## p69 ecosystem (first zemium customer + lamtl provider tenant)

- `p69` — main p69 repo
- `p69-akashic`, `p69-akashic-phase1`, `p69-akashic-phase2` — "akashic" subsystem (records/identity-related, multi-phase)
- `p69-b2b-magic-lookup` — B2B lookup feature
- `p69-identity-run` — identity resolver hardening; **likely already implements provider/customer auth that zemium can reuse**
- `p69-wt/fal-flux` — fal-flux feature worktree
- `p69/.claude/worktrees/zemium-onesignal-adapter` — **the Slice A prior work** (branch `worktree-zemium-onesignal-adapter`, ~1670 LOC, see `projects/zemium.md`)
- `p69/.claude/worktrees/feature-flags`, `homepage-d2-v4-rocket`, `surprise-provider-business-*`, many `agent-*` and `tonight/kill-*` worktrees — parallel agent-driven branches
- `p69/.worktrees/{checkin, go-avail-gold, shifts-sexy}` — additional feature branches

## lamtl ecosystem (parent provider org)

- `lamtl` — main lamtl repo (the parent of p69)
- `lamtl-call-observability` — calls/comms observability; **check before building any new comms instrumentation for zemium**

## Other Golden Focus repos

- `hermes` — name suggests messaging. Investigate as candidate transport for zemium Chat (Slice C) before greenfield design.
- `astro-bot` — purpose unknown, investigate when relevant
- `openclaw` — purpose unknown, investigate when relevant
- `chicoine.org` — public site for chicoine
- `zemium` — currently a stub (`.env.local` + `.gitignore` only); will host the product shell
- `--claude-mem-observer-sessions/` — claude memory observer sessions

## How to use

Before designing **any** subsystem (auth, notifications, chat transport, multi-tenancy, identity, payments, observability) for zemium or any new project: grep these dirs for existing implementations. If something looks reusable, propose extraction → golden block, not duplication.
