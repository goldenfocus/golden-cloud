#!/usr/bin/env bash
# Yan's personal laptop bootstrap.
#
# What this does:
#   1. Runs the public Golden Focus Startup Kit (brew, fish, claude, etc.)
#   2. Clones my work repos
#   3. Decrypts my SOPS secrets into their expected places
#
# Prereq: age keypair must exist at ~/.config/sops/age/keys.txt
#         (on a fresh laptop, you'll generate one and add its pubkey to
#          golden-cloud/.sops.yaml from an existing device first)

set -euo pipefail

say() { printf "\n\033[1;33m▸ %s\033[0m\n" "$*"; }
ok()  { printf "  \033[1;32m✓\033[0m %s\n" "$*"; }

# 1 — Public kit
say "Running public Golden Focus Startup Kit"
curl -fsSL https://raw.githubusercontent.com/goldenfocus/golden-cloud-public/main/startup-kit/install.sh | bash

# 2 — Clone work repos
say "Cloning work repos"
mkdir -p "$HOME"
cd "$HOME"
while IFS= read -r repo; do
  [ -z "$repo" ] || [ "${repo:0:1}" = "#" ] && continue
  name="$(basename "$repo" .git)"
  if [ -d "$name" ]; then
    ok "$name already cloned"
  else
    git clone "$repo" "$name"
    ok "$name cloned"
  fi
done < "$HOME/golden-cloud/laptop/repos.txt"

# 3 — Decrypt secrets into place
# Each line in drop.map: <sops-file-in-golden-cloud>  <destination-path>
say "Placing decrypted secrets"
if [ -f "$HOME/golden-cloud/laptop/drop.map" ]; then
  while IFS=$'\t' read -r src dst; do
    [ -z "$src" ] || [ "${src:0:1}" = "#" ] && continue
    dst_expanded="$(eval echo "$dst")"
    mkdir -p "$(dirname "$dst_expanded")"
    sops -d "$HOME/golden-cloud/$src" > "$dst_expanded"
    chmod 600 "$dst_expanded"
    ok "$src → $dst_expanded"
  done < "$HOME/golden-cloud/laptop/drop.map"
else
  ok "no drop.map yet — create one when you have secrets to deploy"
fi

# 4 — Symlink gc-secret onto $PATH
say "Linking gc-secret onto PATH"
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/golden-cloud/gc-secret.sh" "$HOME/.local/bin/gc-secret"
if command -v gc-secret >/dev/null 2>&1; then
  ok "gc-secret available globally"
else
  ok "symlinked — make sure ~/.local/bin is on \$PATH (fish config in the startup kit handles this)"
fi

# 5 — Wire Golden Focus Intel (shared AI memory) into Claude project memory dirs
say "Wiring Golden Focus Intel into per-project memory dirs"
if [ -x "$HOME/golden-cloud/laptop/gc-memory-sync.sh" ]; then
  bash "$HOME/golden-cloud/laptop/gc-memory-sync.sh" || \
    ok "memory sync skipped (Claude Code not yet run on this laptop — re-run later)"
else
  ok "no gc-memory-sync.sh on disk yet — skipping"
fi

# 6 — Install the auto-sync Stop hook in ~/.claude/settings.json (idempotent)
say "Installing gc-memory auto-sync Stop hook"
if [ -x "$HOME/golden-cloud/laptop/install-claude-stop-hook.sh" ]; then
  bash "$HOME/golden-cloud/laptop/install-claude-stop-hook.sh" || \
    ok "stop-hook install skipped (jq missing? check ~/.claude/settings.json manually)"
else
  ok "no install-claude-stop-hook.sh on disk yet — skipping"
fi

# 7 — Final reminder: set whoami so AIs know whose keyboard this is
WHOAMI_FILE="$HOME/golden-cloud/laptop/whoami.txt"
if [ ! -f "$WHOAMI_FILE" ] || [ ! -s "$WHOAMI_FILE" ]; then
  say "ACTION REQUIRED — set this laptop's identity"
  cat <<EOF
  This laptop has no \`whoami.txt\` yet. Run ONE of:
    echo "yan" > $WHOAMI_FILE
    echo "jr"  > $WHOAMI_FILE
    echo "<your-name>" > $WHOAMI_FILE   # if you're a new teammate
  Then commit + push so other laptops know who you are.
EOF
fi

cat <<'EOF'

─────────────────────────────────────────────────
Yan's layer: done. You are home.
─────────────────────────────────────────────────
EOF
