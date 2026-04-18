# Your Own Golden Cloud — Private Half Setup

The public startup kit gives you the tools. Your **private half** is where your real life lives: secrets, project context, team-shared memory, AI-readable notes.

This guide takes you from zero to a working private cloud in ~5 minutes.

## What you'll have at the end

1. A **private GitHub repo** at `github.com/<you>/golden-cloud` — invite-only
2. **SOPS + age encrypted secrets** — shareable with specific devices/people/AIs
3. A **pre-commit hook** (gitleaks) that blocks accidental plaintext secrets
4. A **publish flow** to move anything public when you're ready

## Step 1 — Create your private repo

```bash
gh repo create <you>/golden-cloud --private --clone --description "Shared brain — me, my laptops, my team, my AI"
cd ~/golden-cloud
```

Or under a GitHub org (recommended if you have coworkers):

```bash
gh repo create <your-org>/golden-cloud --private --clone
```

## Step 2 — Scaffold folders

```bash
mkdir -p memory notes plans prompts blocks assets secrets .githooks
touch memory/.gitkeep notes/.gitkeep plans/.gitkeep prompts/.gitkeep blocks/.gitkeep assets/.gitkeep
```

## Step 3 — Generate your age keypair

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# macOS: symlink to the default SOPS location so it's auto-discovered
mkdir -p "$HOME/Library/Application Support/sops/age"
ln -sf "$HOME/.config/sops/age/keys.txt" "$HOME/Library/Application Support/sops/age/keys.txt"

# Note your public key — this is what goes into .sops.yaml
grep '^# public key:' ~/.config/sops/age/keys.txt
```

## Step 4 — Create `.sops.yaml`

Replace `<your-age-pubkey>` with the output of the `grep` above (starts with `age1...`).

```yaml
# .sops.yaml
creation_rules:
  - path_regex: secrets/.*\.(yaml|yml|env|json)$
    age: >-
      <your-age-pubkey>
```

## Step 5 — Add the gitleaks pre-commit hook

```bash
cat > .gitleaks.toml <<'EOF'
[extend]
useDefault = true

[[allowlists]]
description = "Ignore SOPS-encrypted secrets folder"
paths = ['''secrets/.*''']
EOF

cat > .githooks/pre-commit <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "⚠️  gitleaks not installed. install: brew install gitleaks"
  exit 0
fi
echo "🔍 gitleaks: scanning staged changes..."
if ! gitleaks protect --staged --redact --verbose --config .gitleaks.toml; then
  echo "❌ possible secret in staged changes — encrypt with sops into secrets/ instead"
  exit 1
fi
echo "✅ gitleaks: clean."
EOF

chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
```

## Step 6 — Write your first secret

```bash
cat > /tmp/prod.env <<'EOF'
OPENAI_API_KEY=sk-...
DATABASE_URL=postgres://...
EOF

mv /tmp/prod.env secrets/prod.env
sops --encrypt --in-place secrets/prod.env

# verify decrypt works
sops -d secrets/prod.env
```

## Step 7 — Commit & push

```bash
git add .
git commit -m "init: private golden cloud"
git push -u origin main
```

## Sharing with a coworker / a new laptop / an AI host

On **their** machine:

```bash
brew install sops age gitleaks
age-keygen -o ~/.config/sops/age/keys.txt && chmod 600 ~/.config/sops/age/keys.txt
grep '^# public key:' ~/.config/sops/age/keys.txt   # send this to you
```

Back on **your** machine, add their pubkey to `.sops.yaml` and re-encrypt:

```bash
# edit .sops.yaml, append the new pubkey under `age:`
sops updatekeys secrets/*
git add .sops.yaml secrets/
git commit -m "sops: add <coworker/device>"
git push
```

Give them access to the repo:

```bash
gh api repos/<you>/golden-cloud/collaborators/<their-github> -X PUT -f permission=push
```

They clone, `git config core.hooksPath .githooks`, and they can now read/write encrypted secrets alongside you.

## Revoking access

1. Remove their pubkey from `.sops.yaml`
2. `sops updatekeys secrets/*`
3. **Rotate the actual secrets at their source** (Vercel, Supabase, AWS, etc.) — the revoked party had access to history and may have saved ciphertext. Revocation ≠ rotation.

## Going public with a Golden Block

When you build something reusable and want to share it:

```bash
mkdir -p blocks/<name>/{src,tests,examples}
# fill in README.md, block.json, your code
```

Move to the public half by copying (or using the `publish.sh` pattern from [goldenfocus/golden-cloud](https://github.com/goldenfocus/golden-cloud) once you're feeling fancy).

## Rules

- **Never** commit plaintext secrets. The pre-commit hook is a safety net, not armor.
- **Never** decrypt into the working tree. Decrypt to `/tmp/`, stdin, or use `sops exec-env`.
- **Never** put anything in your public half that you'd regret on page 1 of Hacker News.
