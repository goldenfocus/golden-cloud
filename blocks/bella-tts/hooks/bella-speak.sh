#!/bin/bash
# bella-speak.sh — universal toggle.
# Rules:
#   anything playing (full/recap/narration) → STOP everything, exit
#   nothing playing                          → start full playback
set -euo pipefail

STATE_DIR="$HOME/.claude/bella-tts"
mkdir -p "$STATE_DIR"
PID_FILE="$STATE_DIR/player.pid"
MODE_FILE="$STATE_DIR/player.mode"
PLAYER="$HOME/.claude/hooks/bella-player.py"

# Detect "something playing": either the PID file exists OR there's a stray
# bella/ffplay process (stale PID file, external kill, etc.)
something_playing() {
  [ -f "$PID_FILE" ] && return 0
  pgrep -f "bella-player.py" >/dev/null 2>&1 && return 0
  pgrep -f "ffplay.*mp3" >/dev/null 2>&1 && return 0
  return 1
}

kill_all() {
  if [ -f "$PID_FILE" ]; then
    while IFS= read -r pid; do
      [ -n "${pid:-}" ] && kill "$pid" 2>/dev/null || true
    done < "$PID_FILE"
  fi
  rm -f "$PID_FILE" "$MODE_FILE"
  pkill -f "bella-player.py" 2>/dev/null || true
  pkill -f "ffplay.*mp3" 2>/dev/null || true
}

if something_playing; then
  kill_all
  exit 0
fi

nohup /usr/bin/python3 "$PLAYER" --mode=full >/dev/null 2>&1 &
disown
exit 0
