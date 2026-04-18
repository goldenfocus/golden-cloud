# Golden Focus Startup Kit

> **One command. Few prompts. Golden Elite mode: activated.**

Turn any fresh Mac into a loaded coding workstation in ~10 minutes.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/goldenfocus/golden-cloud-public/main/startup-kit/install.sh | bash
```

*(Coming soon: `curl -fsSL https://get.goldenfocus.io | bash`)*

You'll be asked ~2 questions (git name, git email). Then it runs.

## What you get

**CLI toolbox** — Homebrew with ~30 hand-picked formulae: `gh`, `fish`, `starship`, `zoxide`, `fzf`, `bat`, `eza`, `jq`, `sops`, `age`, `gitleaks`, `ffmpeg`, `btop`, and more.

**Shell** — `fish` with a warm greeting, a rotating motivational quote on every launch, `starship` prompt, and `zoxide` smart-cd.

**Claude Code, loaded** — a Soul-level `CLAUDE.md` ethos, a rich statusline (git branch + dirty state + session context % + 7-day plan usage), and 20+ plugins pre-enabled (`superpowers`, `sentry`, `supabase`, `vercel`, `context7`, `playwright`, `claude-mem`, and friends).

**502 motivational quotes** — one shows on every shell launch. Taste is a muscle. Train it daily.

**Bella TTS hooks** — opt-in text-to-speech so Claude can talk to you.

## What you don't get (on purpose)

- Your secrets — those stay with you, encrypted, in **your own** private half (see below).
- Your project repos — clone whatever you actually work on.
- Your API keys — bring your own Anthropic, OpenAI, Elevenlabs, etc.

## Going elite: your own private half

The kit is the public baseline. For anything sensitive — `.env` files, secrets, personal CLAUDE.md overrides, your team's shared context — you want your own private Golden Cloud.

See [PRIVATE-SETUP.md](./PRIVATE-SETUP.md) for the 5-minute walkthrough: create a private repo, add SOPS+age encryption, share with your coworkers and your AIs.

## Philosophy

- **Public baseline, private layer on top.** The kit is forkable, shareable, remixable. Your secrets/identity stay sovereign.
- **Fast to install, faster to reproduce.** Buy a new Mac, paste one curl command, you're back.
- **Every tool earns its place.** No bloat. If you don't know why it's here, we cut it.
- **Built for the AI era.** Claude Code is a first-class citizen, not an afterthought.

## Questions, issues, requests

Open an issue: https://github.com/goldenfocus/golden-cloud-public/issues

---

*Made by [Golden Focus](https://goldenfocus.io) — vibe coding disturbing apps for the new world.*
