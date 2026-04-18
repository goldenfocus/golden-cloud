#!/bin/bash
# bella-narrate.sh — mid-turn progress narration.
# Usage: bella-narrate.sh "Checking syntax now"
#        echo "Build passed" | bella-narrate.sh
#
# Short, fire-and-forget. Does NOT interrupt an in-progress FULL playback
# (if the user is listening to the previous turn, respect that).
set -euo pipefail

STATE_DIR="$HOME/.claude/bella-tts"
mkdir -p "$STATE_DIR"
MODE_FILE="$STATE_DIR/player.mode"
PLAYER="$HOME/.claude/hooks/bella-player.py"

# Respect an in-flight FULL playback — don't talk over a user-initiated replay
if [ -f "$MODE_FILE" ] && [ "$(head -1 "$MODE_FILE" 2>/dev/null || true)" = "full" ]; then
  exit 0
fi

# Kill previous narrations (but not full playback — handled above)
pkill -f "bella-player.py --mode=say" 2>/dev/null || true
pkill -f "bella-player.py --mode=recap" 2>/dev/null || true

TEXT="${*:-}"
if [ -z "$TEXT" ] && [ ! -t 0 ]; then
  TEXT="$(cat)"
fi
[ -n "$TEXT" ] || exit 0

nohup /usr/bin/python3 "$PLAYER" --mode=say --text "$TEXT" >/dev/null 2>&1 &
disown
exit 0
