#!/bin/bash
# bella-speak.sh — hotkey toggle for FULL-message playback.
# Rules:
#   nothing playing      → start full playback
#   narration playing    → kill it, start full playback
#   full playback going  → stop it (second press)
set -euo pipefail

STATE_DIR="$HOME/.claude/bella-tts"
mkdir -p "$STATE_DIR"
PID_FILE="$STATE_DIR/player.pid"
MODE_FILE="$STATE_DIR/player.mode"
PLAYER="$HOME/.claude/hooks/bella-player.py"

kill_running() {
  if [ -f "$PID_FILE" ]; then
    while IFS= read -r pid; do
      [ -n "${pid:-}" ] && kill "$pid" 2>/dev/null || true
    done < "$PID_FILE"
    rm -f "$PID_FILE" "$MODE_FILE"
  fi
  pkill -f "bella-player.py" 2>/dev/null || true
  pkill -f "ffplay.*mp3" 2>/dev/null || true
}

CURRENT_MODE=""
[ -f "$MODE_FILE" ] && CURRENT_MODE="$(head -1 "$MODE_FILE" 2>/dev/null || true)"

case "$CURRENT_MODE" in
  full)
    # Already playing full → second press = stop
    kill_running
    exit 0
    ;;
  *)
    # Nothing playing, or narration/recap → kill it, start full
    kill_running
    nohup /usr/bin/python3 "$PLAYER" --mode=full >/dev/null 2>&1 &
    disown
    exit 0
    ;;
esac
