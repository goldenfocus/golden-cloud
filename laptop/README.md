# Yan's Laptop — Bootstrap

> New Mac? Tell Claude: **"bootstrap this laptop from Golden Cloud"** and sip coffee.

## What this does

1. Installs the public [Golden Focus Startup Kit](https://github.com/goldenfocus/golden-cloud-public/tree/main/startup-kit) — brew tools, fish, Claude Code config, statusline, quotes, hooks
2. Clones my work repos (`repos.txt`)
3. Decrypts my SOPS secrets and drops them where each tool expects them (`drop.map`)

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

- `bootstrap.sh` — the orchestrator
- `repos.txt` — list of repos to clone (edit freely)
- `drop.map` — maps encrypted secrets → where they go on disk
- `README.md` — this file
