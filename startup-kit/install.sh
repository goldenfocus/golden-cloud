#!/usr/bin/env bash
# Golden Focus Startup Kit — one command to go from fresh Mac to coding.
#
#   curl -fsSL https://get.goldenfocus.io | bash
#
# Idempotent. Re-runnable. Opinionated but commented.

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/goldenfocus/golden-cloud-public/main/startup-kit"
KIT="${HOME}/.goldenfocus-startup-kit"

say()  { printf "\n\033[1;33m▸ %s\033[0m\n" "$*"; }
ok()   { printf "  \033[1;32m✓\033[0m %s\n" "$*"; }
warn() { printf "  \033[1;31m⚠\033[0m %s\n" "$*"; }

# ── 1. Homebrew ────────────────────────────────────────────────────────────────
say "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "installed"
else
  ok "already installed"
fi

# ── 2. Clone the kit locally (for file copies) ─────────────────────────────────
say "Fetching kit"
rm -rf "$KIT"
git clone --depth=1 https://github.com/goldenfocus/golden-cloud-public.git "$KIT.tmp" >/dev/null 2>&1
mv "$KIT.tmp/startup-kit" "$KIT"
rm -rf "$KIT.tmp"
ok "cached at $KIT"

# ── 3. brew bundle ─────────────────────────────────────────────────────────────
say "Installing CLI tools (brew bundle)"
brew bundle --file="$KIT/brew/Brewfile" --no-upgrade
ok "done"

# ── 4. Shell (fish + starship + zoxide) ────────────────────────────────────────
say "Shell: fish + starship + zoxide"
mkdir -p "$HOME/.config/fish/functions"
cp "$KIT/shell/config.fish" "$HOME/.config/fish/config.fish"
cp "$KIT/shell/functions/"*.fish "$HOME/.config/fish/functions/"
cp "$KIT/shell/starship.toml" "$HOME/.config/starship.toml"
ok "fish config + functions + starship placed"

# Add fish to /etc/shells if not present (optional, user runs chsh themselves)
if command -v fish >/dev/null 2>&1 && ! grep -q "$(command -v fish)" /etc/shells 2>/dev/null; then
  warn "to make fish your default shell, run:"
  echo "     echo \$(which fish) | sudo tee -a /etc/shells && chsh -s \$(which fish)"
fi

# ── 5. Claude Code config ──────────────────────────────────────────────────────
say "Claude Code: CLAUDE.md, settings, statusline, hooks, quotes"
mkdir -p "$HOME/.claude/hooks" "$HOME/.claude/bella-tts"

# CLAUDE.md — don't overwrite if user already has one (theirs may be customized)
if [ ! -f "$HOME/.claude/CLAUDE.md" ]; then
  cp "$KIT/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  ok "CLAUDE.md (global Soul) placed"
else
  warn "~/.claude/CLAUDE.md already exists — not overwriting"
  echo "     to adopt the kit version: mv it aside, then re-run this script"
fi

# settings.json — same caution
if [ ! -f "$HOME/.claude/settings.json" ]; then
  cp "$KIT/claude/settings.template.json" "$HOME/.claude/settings.json"
  ok "settings.json placed"
else
  warn "~/.claude/settings.json already exists — not overwriting"
  echo "     merge from: $KIT/claude/settings.template.json"
fi

cp "$KIT/claude/statusline.sh" "$HOME/.claude/statusline.sh"
chmod +x "$HOME/.claude/statusline.sh"
cp "$KIT/claude/quotes.txt" "$HOME/.claude/quotes.txt"
cp "$KIT/claude/hooks/"*.sh "$HOME/.claude/hooks/" 2>/dev/null || true
cp "$KIT/claude/hooks/"*.py "$HOME/.claude/hooks/" 2>/dev/null || true
chmod +x "$HOME/.claude/hooks/"*.sh 2>/dev/null || true
cp "$KIT/claude/bella-tts/config.json" "$HOME/.claude/bella-tts/config.json"
ok "statusline, quotes, hooks, bella-tts placed"

# ── 6. Git identity (prompt if missing) ────────────────────────────────────────
say "Git identity"
if [ -z "$(git config --global user.name || true)" ]; then
  printf "  What's your git user.name? "
  read -r git_name
  git config --global user.name "$git_name"
fi
if [ -z "$(git config --global user.email || true)" ]; then
  printf "  What's your git user.email? "
  read -r git_email
  git config --global user.email "$git_email"
fi
ok "$(git config --global user.name) <$(git config --global user.email)>"

# ── 7. Claude Code itself (if not installed) ───────────────────────────────────
say "Claude Code CLI"
if ! command -v claude >/dev/null 2>&1; then
  warn "Claude Code not found. Install from: https://claude.ai/download"
else
  ok "$(claude --version 2>&1 | head -1)"
fi

# ── 8. Next steps ──────────────────────────────────────────────────────────────
cat <<'EOF'

─────────────────────────────────────────────────
  ██████╗  ██████╗ ██╗     ██████╗ ███████╗███╗   ██╗
 ██╔════╝ ██╔═══██╗██║     ██╔══██╗██╔════╝████╗  ██║
 ██║  ███╗██║   ██║██║     ██║  ██║█████╗  ██╔██╗ ██║
 ██║   ██║██║   ██║██║     ██║  ██║██╔══╝  ██║╚██╗██║
 ╚██████╔╝╚██████╔╝███████╗██████╔╝███████╗██║ ╚████║
  ╚═════╝  ╚═════╝ ╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═══╝
           E L I T E   M O D E   :   A C T I V A T E D
─────────────────────────────────────────────────

Your machine is loaded. Here's what's next:

  1. Restart your terminal (or run: exec fish)
  2. Sign into Claude Code:   claude /login
  3. Set up your private half (secrets, team sharing):
     https://github.com/goldenfocus/golden-cloud-public/blob/main/startup-kit/PRIVATE-SETUP.md
  4. (Optional) Make fish your default shell — see warning above.

Questions, issues, upgrades:
  https://github.com/goldenfocus/golden-cloud-public/issues

Ship something today.
─────────────────────────────────────────────────
EOF
