#!/bin/bash
# bella-reset.sh — kills any playback, clears stuck title on the current tab.
set -euo pipefail

STATE_DIR="$HOME/.claude/bella-tts"
PID_FILE="$STATE_DIR/player.pid"
MODE_FILE="$STATE_DIR/player.mode"

# Kill playback
if [ -f "$PID_FILE" ]; then
  while IFS= read -r pid; do
    [ -n "${pid:-}" ] && kill "$pid" 2>/dev/null || true
  done < "$PID_FILE"
fi
pkill -f "bella-player.py" 2>/dev/null || true
pkill -f "ffplay.*mp3" 2>/dev/null || true
rm -f "$PID_FILE" "$MODE_FILE"

# Restore title on current tty via pop + empty-title fallback
TTY_PATH="$(tty 2>/dev/null || true)"
if [ -z "$TTY_PATH" ] || [ "$TTY_PATH" = "not a tty" ]; then
  # Walk ancestors
  pid=$$
  for _ in 1 2 3 4 5 6 7 8; do
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [ -z "$pid" ] && break
    [ "$pid" = "0" ] || [ "$pid" = "1" ] && break
    tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$tty" ] && [ "$tty" != "?" ] && [ "$tty" != "??" ]; then
      TTY_PATH="/dev/$tty"
      break
    fi
  done
fi

if [ -n "${TTY_PATH:-}" ] && [ -w "$TTY_PATH" ]; then
  # Pop xterm title stack, then clear — shell will re-set on next prompt
  printf '\033[23;0t\033]0;\007' > "$TTY_PATH"
fi

echo "bella: reset (killed playback, cleared title)"
