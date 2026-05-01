# Golden Focus Laptop — Bootstrap & Enrollment

> New Mac? Tell Claude: **"bootstrap this laptop from Golden Cloud"** and sip coffee.
>
> New teammate? See [`ENROLLMENT.md`](./ENROLLMENT.md) for the canonical onboarding flow.

## What `bootstrap.sh` does

1. Installs the public [Golden Focus Startup Kit](https://github.com/goldenfocus/golden-cloud-public/tree/main/startup-kit) — brew tools, fish, Claude Code config, statusline, quotes, hooks
2. Clones the work repos (`repos.txt`)
3. Decrypts SOPS secrets and drops them where each tool expects them (`drop.map`)
4. Symlinks `gc-secret` onto `$PATH`
5. **Wires Golden Focus Intel** — symlinks `~/.claude/projects/*/memory/shared/` to `~/golden-cloud/memory/` so every AI session reads the shared brain (`gc-memory-sync.sh`)
6. **Installs the auto-sync Stop hook** — every Claude session end, any new shared-memory writes auto-commit + push to golden-cloud (`install-claude-stop-hook.sh`)
7. Reminds you to set `whoami.txt` if missing

## Prerequisites on a fresh laptop

1. **Sign into GitHub** so `gh` works: `gh auth login`
2. **Generate an age key** for this laptop and add its pubkey to `.sops.yaml` from an existing laptop:
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   mkdir -p "$HOME/Library/Application Support/sops/age"
   ln -sf ~/.config/sops/age/keys.txt "$HOME/Library/Application Support/sops/age/keys.txt"
   grep '^# public key:' ~/.config/sops/age/keys.txt
   # send this pubkey to an existing device, have it run:
   #   edit .sops.yaml, append pubkey under `age:`
   #   sops updatekeys secrets/*
   #   git push
   ```
3. Clone Golden Cloud:
   ```bash
   gh repo clone goldenfocus/golden-cloud ~/golden-cloud
   cd ~/golden-cloud && git pull
   ```

## Run it

```bash
bash ~/golden-cloud/laptop/bootstrap.sh
```

## The "one-thing-to-Claude" version

Once you've done the two prereqs above, you can just say to Claude:

> "Bootstrap this laptop from Golden Cloud."

Claude knows (from memory) to run `~/golden-cloud/laptop/bootstrap.sh`, answer git prompts with your identity, and confirm everything landed.

## Files

- `bootstrap.sh` — the orchestrator (run on a fresh laptop)
- `repos.txt` — list of repos to clone (edit freely)
- `drop.map` — maps encrypted secrets → where they go on disk
- `whoami.txt` — this laptop's identity (`jr`, `yan`, or future teammate's name)
- `gc-memory-sync.sh` — wires per-project Claude memory dirs to `~/golden-cloud/memory/` (idempotent, safe to re-run)
- `gc-memory-autocommit.sh` — invoked by the Claude Stop hook; commits + pushes any shared-memory changes
- `install-claude-stop-hook.sh` — idempotently installs the auto-sync Stop hook in `~/.claude/settings.json`
- `ENROLLMENT.md` — canonical onboarding doc for new laptops AND new teammates
- `README.md` — this file
