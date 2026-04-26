---
name: Rule — never echo decrypted secret values back to the user
description: Decrypted secrets are used internally; success is reported by name, not by value
type: project
---

**Rule:** When you decrypt a secret to use it (via `sops -d` or `sops exec-env` or any other path), **never echo the decrypted value back to the user in your visible response** — unless the user explicitly asks ("show me the key", "print it", etc.).

**Why:** Responses are persisted (transcripts, screenshots, copy/paste, screen-share recordings). A value that exists only in your runtime memory has a much smaller blast radius than one rendered into the chat. A secret rendered to the screen is, for practical purposes, leaked.

**How to apply:**

- After a successful decrypt: report `"set OPENAI_API_KEY in ~/project/.env.local — value retrieved from secrets/openai.env"` (file + key name, not value).
- After a successful injection (`sops exec-env`): report `"ran <command> with prod env injected"` — don't print env vars.
- If the user explicitly asks to see the value: confirm intent once if it would land in a logged context (e.g., a shared screen), then comply.
- Never store a decrypted value in long-lived memory (notes, plans, MEMORY.md, CLAUDE.md, anywhere persistent) — see `decrypt-discipline.md`.
