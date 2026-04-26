---
name: Rule — decrypt discipline (where secrets may live; what gets cached)
description: Decrypted values land at the destination path the consumer expects, never inside a git working tree (unless gitignored), never cached in long-lived memory
type: project
---

**Rule:** When you decrypt a secret:

1. **Allowed destinations:**
   - The exact path the consumer needs (e.g., `~/p69/.env.production.local` — note: `.env*.local` is gitignored in p69).
   - `/tmp/` for one-shot use.
   - Process env via `sops exec-env <secrets-file> "<command>"`.
2. **Forbidden destinations:**
   - Any path inside a git working tree that is **not** gitignored.
   - Any "memory" surface: `MEMORY.md`, `CLAUDE.md`, `notes/`, `plans/`, conversation summaries, README files.
   - Any cache that survives the session (no caching the value to a variable that gets serialized).
3. **Re-decrypt on demand.** Don't cache a decrypted value to "save time" — `sops -d` is fast enough.
4. **If a decrypt fails:** surface the error to the user. Do **not** fall back to asking the user to paste the secret in chat — that defeats the purpose.

**Why:** The trust model is "this laptop has the age key, decryption is allowed; the result of decryption stays ephemeral." Anything that escapes that ephemeral envelope is a leak.

**Canonical mapping** of which secret file goes to which destination path lives in `~/golden-cloud/laptop/drop.map` — that's the source of truth, source bootstrap reads it.
