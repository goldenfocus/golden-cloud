# Enrolling a new laptop / new teammate in Golden Focus

This is the canonical onboarding doc — the same flow whether yan adds a second laptop, JR moves to a new machine, or a new teammate joins the team.

> **The 30-second version:** clone golden-cloud → run `bootstrap.sh` → set `whoami.txt` → done.

## Who's running this?

- **Existing person, new laptop** (yan's MacBook 2; JR's spare; etc.) → just **Scenario A** below.
- **Brand new teammate** (someone not yet in the trust circle) → an **already-enrolled** person does Scenario B once, then the new teammate runs Scenario A.

---

## Scenario A — onboard a laptop (existing person OR new teammate)

### Prereqs (one-time per laptop, before bootstrap)

```bash
# 1. Sign into GitHub so `gh` works
gh auth login

# 2. Generate this laptop's age key (so it can decrypt golden-cloud secrets)
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# 3. Send the public key to an already-enrolled laptop:
grep '^# public key:' ~/.config/sops/age/keys.txt
#    The other laptop appends it under `age:` in golden-cloud/.sops.yaml,
#    runs `sops updatekeys secrets/*`, commits, pushes.

# 4. Clone golden-cloud
gh repo clone goldenfocus/golden-cloud ~/golden-cloud
cd ~/golden-cloud && git pull
```

### Run bootstrap

```bash
bash ~/golden-cloud/laptop/bootstrap.sh
```

This single command:
1. Installs the public Golden Focus Startup Kit (brew, fish, Claude Code config, statusline, hooks)
2. Clones the work repos in `repos.txt`
3. Decrypts every SOPS secret listed in `drop.map` to its destination path
4. Symlinks `gc-secret` onto `$PATH`
5. **Wires Golden Focus Intel** — symlinks `~/.claude/projects/*/memory/shared/` to `~/golden-cloud/memory/`
6. **Installs the auto-sync Stop hook** in `~/.claude/settings.json` (idempotent; preserves any existing hooks)
7. Reminds you to set `whoami.txt` if missing

### Tell the laptop who you are

```bash
echo "<your-name>" > ~/golden-cloud/laptop/whoami.txt
# valid: jr | yan | <future-teammate>
```

The Stop hook will auto-commit + push this on the next Claude session end. Other laptops pick it up on next pull.

### Verify

```bash
# Sanity check: shared memory accessible from a Claude project
ls ~/.claude/projects/*/memory/shared/AGENTS.md   # should print N existing files

# Hook installed?
jq -r '.hooks.Stop[].hooks[].command' ~/.claude/settings.json | grep gc-memory
```

---

## Scenario B — admit a new teammate (one-time, by an already-enrolled person)

Before the new teammate runs Scenario A, you (or someone already enrolled) must:

1. **Add their age public key** to `~/golden-cloud/.sops.yaml` under the `age:` block.
2. **Re-encrypt secrets for the new recipient:**
   ```bash
   cd ~/golden-cloud
   sops updatekeys secrets/*
   git add .sops.yaml secrets/
   git commit -m "enroll: add <name>'s age key"
   ```
   (The auto-sync Stop hook handles the push; or push manually.)
3. **Create their user profile** so every AI knows who they are:
   ```bash
   $EDITOR ~/golden-cloud/memory/users/<name>.md
   ```
   Copy `users/jr.md` or `users/yan.md` as a template. Add a line to `~/golden-cloud/memory/MEMORY.md` under `## Users`. Both files auto-commit on next Stop.

The new teammate then runs Scenario A.

---

## What lives where

| Path | What | Who maintains |
|---|---|---|
| `~/golden-cloud/.sops.yaml` | recipient pubkeys | added once per laptop |
| `~/golden-cloud/secrets/*` | SOPS-encrypted env files | `gc-secret.sh` |
| `~/golden-cloud/laptop/drop.map` | secret → disk-path mapping | edited by hand when adding a new secret |
| `~/golden-cloud/laptop/repos.txt` | repos auto-cloned by bootstrap | edited by hand |
| `~/golden-cloud/laptop/whoami.txt` | this-laptop-is-whose | per-laptop, set after bootstrap |
| `~/golden-cloud/memory/users/<name>.md` | user profile (style, role) | per-person, committed once |
| `~/.claude/projects/*/memory/shared/` | symlink → `~/golden-cloud/memory/` | created by `gc-memory-sync.sh` |
| `~/.claude/settings.json` Stop hook | runs `gc-memory-autocommit.sh` on every Claude turn end | installed by `install-claude-stop-hook.sh` |

---

## Common gotchas

- **`gc-memory-sync.sh` says "Claude Code hasn't run"** — first launch Claude Code at least once, then re-run bootstrap (or just `bash ~/golden-cloud/laptop/gc-memory-sync.sh`).
- **`sops -d` fails on an enrolled laptop** — confirm the symlink exists at `~/Library/Application Support/sops/age/keys.txt → ~/.config/sops/age/keys.txt`. macOS sops looks at the Library path.
- **Stop hook isn't firing** — open `/hooks` in Claude Code once to force a settings reload, or restart the CLI. The watcher caches at session start.
- **Two people pushing to golden-cloud at once** — `gc-memory-autocommit.sh` does `git pull --rebase` before pushing, so collisions resolve automatically. Manual pushes should also `--rebase`.
