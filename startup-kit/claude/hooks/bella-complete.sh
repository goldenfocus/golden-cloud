#!/bin/bash
# bella-complete.sh — fires on Claude Code's Stop event.
# 1. Updates the active-session pointer
# 2. Plays a short chime
# 3. Triggers an auto-recap (first ~200 chars of the response)
#
# Runs detached so the Stop hook returns instantly.
exec 2>>"$HOME/.claude/bella-tts/complete.log"
set -eu

STATE_DIR="$HOME/.claude/bella-tts"
mkdir -p "$STATE_DIR"

HOOK_JSON="$(cat)"
TRANSCRIPT=$(printf '%s' "$HOOK_JSON" | jq -r '.transcript_path // empty' 2>/dev/null || true)

if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  printf '%s\n' "$TRANSCRIPT" > "$STATE_DIR/active-transcript"
fi

# Respect user's in-flight FULL playback — don't talk over a replay
MODE_FILE="$STATE_DIR/player.mode"
CURRENT_MODE=""
[ -f "$MODE_FILE" ] && CURRENT_MODE="$(head -1 "$MODE_FILE" 2>/dev/null || true)"

if [ "$CURRENT_MODE" = "full" ]; then
  printf '{"continue":true,"suppressOutput":true}\n'
  exit 0
fi

# Chime + recap in background so Stop returns instantly
(
  afplay /System/Library/Sounds/Tink.aiff >/dev/null 2>&1 || true
  # Small gap so chime doesn't collide with first word
  sleep 0.25
  /usr/bin/python3 "$HOME/.claude/hooks/bella-player.py" --mode=recap >/dev/null 2>&1 || true
) >/dev/null 2>&1 &
disown

printf '{"continue":true,"suppressOutput":true}\n'
exit 0
