---
name: Golden Cloud — operating manual pointer
description: ~/golden-cloud/ is yan's shared brain; AI.md is the authoritative manual; trigger phrases require consulting it first
type: reference
---

`~/golden-cloud/` is yan's "shared brain across laptops, people, and AIs" (per `AGENTS.md`). Canonical home for:

- **Secrets** (`secrets/`) — SOPS+age encrypted; manage via `~/golden-cloud/gc-secret.sh` (always pipe stdin, never CLI args). Audit log at `secrets/AUDIT.md`. Pass `--purpose "..."` when writing.
- **Reusable blocks** (`blocks/`) — API-first tested modules; bootstrap with `./new-block.sh <name>`. Public counterpart: `~/golden-cloud-public/blocks/`.
- **Prompts / notes / plans / assets** — each in its own dir, plain files + git commit/push.
- **Memory** (`memory/`) — the AI-memory layer that contains this very file. See `memory/AGENTS.md`.
- **Laptop bootstrap** (`laptop/bootstrap.sh`, `laptop/drop.map`, `laptop/whoami.txt`, `laptop/gc-memory-sync.sh`) — drops decrypted secrets to their target paths and wires shared memory on a fresh laptop.

## Trigger phrases

Read `~/golden-cloud/AI.md` whenever the user says any of: **Golden Cloud**, **Gold Cloud**, **Golden Secret**, **Golden Vault**, **Golden Focus** (storage context), **the cloud** (about his stuff), **the vault** — or asks to **put / save / store / stash / park / drop / add** anything secret-shaped or context-shaped.

## Hard rules (also enforced via memory/rules/)

See `rules/no-plaintext-secrets.md`, `rules/never-echo-secrets.md`, `rules/decrypt-discipline.md`. The full protocol (trust model, disambiguation table, add/read/rotate commands, enrollment flow) is in `~/golden-cloud/AI.md`.

**For any new question about secrets, blocks, prompts, or how the shared brain works: re-read `~/golden-cloud/AI.md` directly.** This memory file is just the pointer — the AI.md file is the source of truth.
