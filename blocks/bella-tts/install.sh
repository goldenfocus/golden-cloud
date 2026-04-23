#!/bin/bash
# bella-tts/install.sh — one-command installer for Bella TTS in Claude Code.
# Usage: bash ~/golden-cloud-public/blocks/bella-tts/install.sh [ELEVENLABS_API_KEY]
set -euo pipefail

BLOCK_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$HOME/.claude/hooks"
STATE_DIR="$HOME/.claude/bella-tts"
SETTINGS="$HOME/.claude/settings.json"

echo "=== Bella TTS — Claude Code voice narration ==="
echo

# --- prerequisites ---
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "error: macOS only (uses Keychain, afplay, ffplay)" >&2
  exit 1
fi

for bin in jq ffplay curl; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "missing: $bin — install with: brew install jq ffmpeg" >&2
    exit 1
  fi
done

# --- copy hooks ---
mkdir -p "$HOOKS_DIR" "$STATE_DIR"
cp "$BLOCK_DIR/hooks/"*.sh "$HOOKS_DIR/"
cp "$BLOCK_DIR/hooks/"*.py "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR"/bella-*.sh "$HOOKS_DIR"/bella-player.py
echo "copied hooks to $HOOKS_DIR"

# --- store API key ---
API_KEY="${1:-}"
if [ -z "$API_KEY" ]; then
  existing=$(security find-generic-password -a "$USER" -s "ELEVENLABS_API_KEY" -w 2>/dev/null || true)
  if [ -n "$existing" ]; then
    echo "ElevenLabs key already in Keychain — keeping it"
    API_KEY="$existing"
  else
    read -rsp "ElevenLabs API key: " API_KEY
    echo
  fi
fi
[ -n "$API_KEY" ] || { echo "no key provided"; exit 1; }
security add-generic-password -a "$USER" -s "ELEVENLABS_API_KEY" -w "$API_KEY" -U 2>/dev/null
echo "key stored in Keychain"

# --- find voice ---
VOICE_ID=$(curl -s -H "xi-api-key: $API_KEY" "https://api.elevenlabs.io/v1/voices" \
  | jq -r '.voices[]? | select(.name | test("bella"; "i")) | .voice_id' | head -1)
if [ -z "$VOICE_ID" ]; then
  VOICE_ID="EXAVITQu4vr4xnSDxMaA"
  echo "no Bella voice on account — using canonical ID $VOICE_ID"
else
  echo "found Bella voice: $VOICE_ID"
fi

cat > "$STATE_DIR/config.json" <<JSON
{
  "voice_id": "$VOICE_ID",
  "model_id": "eleven_turbo_v2_5",
  "char_cap": 5000
}
JSON
echo "config written to $STATE_DIR/config.json"

# --- wire hooks into settings.json ---
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

ALREADY_WIRED=$(jq -r '.hooks.Stop // [] | .[].hooks[]? | select(.command | test("bella")) | .command' "$SETTINGS" 2>/dev/null || true)
if [ -n "$ALREADY_WIRED" ]; then
  echo "hooks already wired in settings.json — skipping"
else
  TEMP=$(mktemp)
  jq '
    .hooks //= {} |
    .hooks.UserPromptSubmit //= [] |
    .hooks.Stop //= [] |
    .hooks.UserPromptSubmit += [{"hooks": [{"type": "command", "command": "~/.claude/hooks/bella-pointer.sh"}]}] |
    .hooks.Stop += [{"hooks": [{"type": "command", "command": "~/.claude/hooks/bella-complete.sh"}]}]
  ' "$SETTINGS" > "$TEMP" && mv "$TEMP" "$SETTINGS"
  echo "wired hooks into $SETTINGS"
fi

# --- test ---
echo
echo "testing voice..."
/usr/bin/python3 "$HOOKS_DIR/bella-player.py" --mode=say --text "Bella here. Ready when you are." 2>/dev/null || true

echo
echo "=== done ==="
echo
echo "What you get:"
echo "  - Auto recap: Claude reads a summary aloud when it finishes (Stop hook)"
echo "  - Full replay: bash ~/.claude/hooks/bella-speak.sh (bind to a hotkey)"
echo "  - Read selection: bash ~/.claude/hooks/bella-speak-selection.sh (bind to a hotkey)"
echo "  - Mid-turn narration: bash ~/.claude/hooks/bella-narrate.sh 'checking now...'"
echo "  - Status: bash ~/.claude/hooks/bella-status.sh"
echo "  - Reset: bash ~/.claude/hooks/bella-reset.sh"
echo
echo "Hotkey tip (skhd): add to ~/.skhdrc:"
echo '  alt - b : bash ~/.claude/hooks/bella-speak.sh'
echo '  alt + shift - b : bash ~/.claude/hooks/bella-speak-selection.sh'
