#!/usr/bin/env bash
# install-claude-stop-hook.sh — idempotently merge gc-memory-autocommit.sh into
# ~/.claude/settings.json as a Stop hook. Preserves any existing hooks.
#
# Safe to re-run. Detects existing installation by matching the command path.
# Creates ~/.claude/settings.json if it doesn't exist.

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
HOOK_CMD='~/golden-cloud/laptop/gc-memory-autocommit.sh'
TIMEOUT=30

mkdir -p "$(dirname "$SETTINGS")"

# Fresh install: no settings.json yet
if [ ! -f "$SETTINGS" ]; then
  cat > "$SETTINGS" <<EOF
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "$HOOK_CMD", "timeout": $TIMEOUT }
        ]
      }
    ]
  }
}
EOF
  echo "✓ created $SETTINGS with gc-memory Stop hook"
  exit 0
fi

# Validate existing JSON
if ! jq empty "$SETTINGS" 2>/dev/null; then
  echo "ERR: $SETTINGS is not valid JSON — fix manually first" >&2
  exit 1
fi

# Already installed? (match by command path)
if jq -e --arg cmd "$HOOK_CMD" \
   '(.hooks.Stop // []) | map((.hooks // []) | map(.command == $cmd) | any) | any' \
   "$SETTINGS" > /dev/null; then
  echo "✓ gc-memory Stop hook already installed"
  exit 0
fi

# Append our hook block to .hooks.Stop, creating intermediate keys as needed
tmp=$(mktemp)
jq --arg cmd "$HOOK_CMD" --argjson timeout "$TIMEOUT" '
  .hooks //= {} |
  .hooks.Stop //= [] |
  .hooks.Stop += [{
    "hooks": [{ "type": "command", "command": $cmd, "timeout": $timeout }]
  }]
' "$SETTINGS" > "$tmp"

if ! jq empty "$tmp" 2>/dev/null; then
  echo "ERR: jq output is invalid JSON — refusing to overwrite" >&2
  rm -f "$tmp"
  exit 1
fi

mv "$tmp" "$SETTINGS"
echo "✓ added gc-memory Stop hook to $SETTINGS (existing hooks preserved)"
