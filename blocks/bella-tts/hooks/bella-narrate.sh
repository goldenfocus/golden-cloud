#!/bin/bash
# bella-narrate.sh — mid-turn progress narration.
# Usage: bella-narrate.sh "Checking syntax now"
#        echo "Build passed" | bella-narrate.sh
# Tags the firing Ghostty tab with a pulsing 🔊 indicator.
set -euo pipefail

STATE_DIR="$HOME/.claude/bella-tts"
mkdir -p "$STATE_DIR"
MODE_FILE="$STATE_DIR/player.mode"
PLAYER="$HOME/.claude/hooks/bella-player.py"

# Respect in-flight full playback — don't interrupt a replay
if [ -f "$MODE_FILE" ] && [ "$(head -1 "$MODE_FILE" 2>/dev/null || true)" = "full" ]; then
  exit 0
fi

pkill -f "bella-player.py --mode=say" 2>/dev/null || true
pkill -f "bella-player.py --mode=recap" 2>/dev/null || true

TEXT="${*:-}"
if [ -z "$TEXT" ] && [ ! -t 0 ]; then
  TEXT="$(cat)"
fi
[ -n "$TEXT" ] || exit 0

# Walk ancestor PIDs to find a real TTY — that's the Ghostty tab we're in
find_parent_tty() {
  local pid=$$
  for _ in 1 2 3 4 5 6 7 8; do
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [ -z "$pid" ] && break
    [ "$pid" = "0" ] || [ "$pid" = "1" ] && break
    local tty
    tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$tty" ] && [ "$tty" != "?" ] && [ "$tty" != "??" ]; then
      echo "/dev/$tty"
      return 0
    fi
  done
  return 1
}

LABEL="$(basename "$PWD" 2>/dev/null || echo "")"
TTY_ARGS=()
if TTY_PATH=$(find_parent_tty) && [ -n "$TTY_PATH" ] && [ -w "$TTY_PATH" ]; then
  TTY_ARGS=(--tty "$TTY_PATH" --label "$LABEL")
fi

nohup /usr/bin/python3 "$PLAYER" --mode=say --text "$TEXT" "${TTY_ARGS[@]}" >/dev/null 2>&1 &
disown
exit 0
