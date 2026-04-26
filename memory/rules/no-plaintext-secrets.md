---
name: Rule — never commit plaintext secrets
description: API keys, tokens, credentials, passwords, .env contents must never be committed in plaintext to any repo, anywhere
type: project
---

**Rule:** Never commit plaintext secrets — API keys, tokens, credentials, passwords, `.env` file contents, service-role keys, signing keys, etc. — to any repo, public or private, ever.

**Why:** Once committed, even a force-push doesn't fully erase. Treat any secret that ever touched git as compromised → rotate at source. The Golden Cloud pre-commit hook runs `gitleaks` to catch most of this, but **don't rely on the hook** — assume it can be bypassed (network failure, missing install, false negative).

**How to apply:**

- For new secrets → encrypt with SOPS into `~/golden-cloud/secrets/`. Use the helper:
  ```
  echo "$VAL" | ~/golden-cloud/gc-secret.sh set <file> <KEY> --purpose "why this is here"
  ```
  Always pipe via stdin, never as a CLI argument (leaks into `ps` and shell history).
- For existing plaintext you find → tell the user, rotate at source (the vendor dashboard), then encrypt the new value. Don't quietly delete and pretend it didn't happen.
- For test/example values that look like secrets but aren't → add the path to `.gitleaks.toml` allowlists.
- For `.env*.local` files → these are gitignored in the projects that use them; verify gitignore coverage before writing.

**What this rule does NOT block:** writing prose ABOUT a secret (e.g., "this app needs a OneSignal key in `.env.local`") — that's fine. Just never paste the value itself.
