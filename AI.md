# For AI collaborators — how to read and write Golden Cloud

> Read this doc whenever the user mentions **Golden Cloud**, **Gold Cloud**, **Golden Secret**, **Golden Vault**, **Golden Focus** (in a storage context), **the cloud** (when talking about his own stuff), **the vault**, or asks you to **put / save / store / stash / park / drop / add** anything that looks like a secret, API key, credential, `.env`, artifact, prompt, note, or reusable block.

## Disambiguating "put this in Golden Cloud"

When the user says "put this in Golden Cloud" (or any alias above), **figure out which bucket it belongs in**:

| If the content is… | It goes in… | How |
|---|---|---|
| API key, token, credential, `.env` contents, anything secret | `~/golden-cloud/secrets/` | `echo "$VAL" \| gc-secret set <file> <KEY>` |
| Prompt, template, system message | `~/golden-cloud/prompts/` or `~/golden-cloud-public/prompts/` | plain file write + git commit/push |
| Note, idea, journal entry | `~/golden-cloud/notes/` (private) or `~/golden-cloud-public/notes/` (public) | plain file + commit/push |
| Reusable, API-first, tested module | `~/golden-cloud/blocks/<name>/` (private) or `~/golden-cloud-public/blocks/<name>/` (public) | `./new-block.sh <name>` |
| Plan, spec, roadmap | `~/golden-cloud/plans/` | plain file + commit/push |
| Image, PDF, binary | `~/golden-cloud/assets/` or `~/golden-cloud-public/assets/` | plain file + commit/push |
| Design mockup (HTML, p69 project) | **not Golden Cloud** — use `~/p69/scripts/add-design.sh` | publishes to `p69.io/designs/...` |

**When uncertain, ask the user once.** Don't guess wrong and put a secret in `notes/`.

## Trust model (read this first)

## Trust model (read this first)

- Secrets live **encrypted** in `~/golden-cloud/secrets/` (SOPS + age).
- This laptop can decrypt them *iff* it has an enrolled age key at `~/.config/sops/age/keys.txt`.
- Whether you're a Claude Code session, a Cursor agent, a Copilot CLI, or any other AI with shell access: if you're running on this laptop as this user, you have the same access as the user does. No separate auth.
- Never write plaintext secrets to files inside the repo working tree. Decrypt to `/tmp/`, into env vars via `sops exec-env`, or to the destination path the tool actually consumes (e.g. `.env.production.local` outside the repo).

## How to check access

```bash
# 1. Is the age key enrolled?
test -f ~/.config/sops/age/keys.txt && echo "age key present" || echo "NO age key — enrollment needed"

# 2. Can you decrypt a known file?
sops -d ~/golden-cloud/secrets/p69-prod.env > /dev/null 2>&1 && echo "decrypt works" || echo "decrypt FAILED"
```

If either check fails, stop and tell the user: **"this laptop isn't enrolled in Golden Cloud yet — see `~/golden-cloud/secrets/README.md` step ‘Adding a new laptop’."**

## Map of what's where

| Secret | Path in Golden Cloud | Destination when decrypted |
|---|---|---|
| p69 production env (Supabase URL + service role key + everything on Vercel prod) | `secrets/p69-prod.env` | `~/p69/.env.production.local` |
| *(more will be added to `laptop/drop.map` over time)* | | |

Canonical mapping lives in `~/golden-cloud/laptop/drop.map` — always source of truth.

## Adding, updating, rotating secrets — USE `gc-secret`

When the user asks you to **save, store, put, add, update, or rotate** a secret (API key, token, credential, `.env` file, etc.) — use the `gc-secret` helper at `~/golden-cloud/gc-secret.sh`. It handles encryption, commit, and push atomically.

**Always pipe the value via stdin — never as a CLI argument.** Arguments leak into shell history and `ps`.

**Provenance is required.** Every write to `secrets/*` appends a line to `secrets/AUDIT.md` recording *who, when, what, why*. Pass a purpose via `--purpose "..."` (or `-p`, or `GC_PURPOSE=`). If stdin is a TTY (human at terminal), the script will prompt for it; if piped (AI/script), it records `(no purpose recorded)` — which is better than nothing but a user reviewing the log will notice. **Always pass a purpose when you know it.**

### Add or update a single key

```bash
echo "$VALUE" | ~/golden-cloud/gc-secret.sh set <file> <KEY> --purpose "why this is here"
```

- If `<file>` doesn't exist → it's created.
- If `<KEY>` already exists in the file → it's replaced.
- If `<KEY>` is new → it's appended.
- Automatic: SOPS encryption, git commit, git push.

Example:

```bash
echo "$NEW_OPENAI_KEY" | ~/golden-cloud/gc-secret.sh set openai.env OPENAI_API_KEY
```

### Replace an entire file

```bash
~/golden-cloud/gc-secret.sh put <file> --purpose "why this is here" < /path/to/plaintext
# or inline:
cat <<'EOF' | ~/golden-cloud/gc-secret.sh put new-service.env --purpose "outbound email vendor"
KEY_A=value_a
KEY_B=value_b
EOF
```

### See the audit log

```bash
~/golden-cloud/gc-secret.sh audit         # last 20 entries
~/golden-cloud/gc-secret.sh audit 100     # last 100
```

Or just open `~/golden-cloud/secrets/AUDIT.md` — it's human-readable Markdown.

### Rotate (interactive, hides input)

```bash
~/golden-cloud/gc-secret.sh rotate <file> <KEY>
```

### Read it back (if the user wants to verify)

```bash
~/golden-cloud/gc-secret.sh get <file> <KEY>
```

### How to pick a filename

- One file per service/vendor when possible: `openai.env`, `resend.env`, `mailgun.env`, `supabase-admin.env`.
- Scope prod vs dev if it matters: `p69-prod.env`, `p69-dev.env`.
- If you're adding a secret that's destined to land at a specific path on disk (e.g. `~/project/.env.local`), also add a line to `~/golden-cloud/laptop/drop.map` so future laptops get it via `bootstrap.sh`.

### Hard don'ts when writing secrets

- **Never** write plaintext to any file under `~/golden-cloud/` yourself — always go through `sops` or `gc-secret`. The `secrets/` folder is gitleaks-allowlisted precisely because it's expected to contain SOPS ciphertext; plaintext there would still be committed.
- **Never** pass the secret as a CLI argument: `gc-secret set file KEY some_value` ← leaks into history. Pipe stdin.
- **Never** echo the value back to the user in your response. Acknowledge success with file + key name, not the value.
- **Never** skip the commit/push. A locally-encrypted-but-not-pushed secret helps no one else — and `gc-secret` pushes for you automatically; just don't work around it.

---

## Common requests → exact commands

### "Get me the p69 service role key"

```bash
sops -d ~/golden-cloud/secrets/p69-prod.env | awk -F= '/^SUPABASE_SERVICE_ROLE_KEY=/ {print $2; exit}'
```

### "Make the design archive script work" (needs `.env.production.local`)

```bash
sops -d ~/golden-cloud/secrets/p69-prod.env > ~/p69/.env.production.local
chmod 600 ~/p69/.env.production.local
```

### "Run <command> with the prod env injected, without touching disk"

```bash
sops exec-env ~/golden-cloud/secrets/p69-prod.env "<command>"
```

Example:

```bash
sops exec-env ~/golden-cloud/secrets/p69-prod.env "pnpm tsx scripts/some-admin-script.ts"
```

### "Bootstrap all secrets onto this laptop"

```bash
bash ~/golden-cloud/laptop/bootstrap.sh
```

That script walks `drop.map` and decrypts each secret into its destination path. Safe to re-run.

## Rules

1. **Never commit plaintext secrets**, anywhere, under any circumstances. The gitleaks pre-commit hook in both repos will try to block you; don't rely on it, don't bypass it.
2. **Never paste a decrypted secret into a response the user can see** unless the user explicitly asks ("show me the key"). Use the secret internally; report success without echoing the value.
3. **Never cache decrypted values in long-lived memory** (conversation notes, plan files, etc.). Re-decrypt on demand.
4. **Never decrypt into the git working tree** unless the path is gitignored. `.env*.local` are gitignored in p69; check before writing elsewhere.
5. **If a decrypt fails**, surface that to the user. Do not fall back to asking the user to paste the secret — that defeats the point.

## Enrollment (when a new laptop/AI/person needs access)

Full guide: `~/golden-cloud/secrets/README.md` → "Adding a new laptop / person / AI device"

Short version:
1. New device generates `age-keygen -o ~/.config/sops/age/keys.txt`
2. Sends its public key (starts with `age1...`) to an existing enrolled device
3. Existing device adds it to `.sops.yaml`, runs `sops updatekeys secrets/*`, commits, pushes
4. New device pulls, can now decrypt

## Revocation

Removing a recipient from `.sops.yaml` only stops **future** encryptions. Treat revocation as "rotate the actual secret at source" (Vercel, Supabase dashboard, etc.) — the revoked party had history access.
