#!/bin/bash
# bella-status.sh — shows what Bella is currently doing.
# Usage: bash ~/.claude/hooks/bella-status.sh
set -euo pipefail

STATE_DIR="$HOME/.claude/bella-tts"
PID_FILE="$STATE_DIR/player.pid"
MODE_FILE="$STATE_DIR/player.mode"
POINTER="$STATE_DIR/active-transcript"

if [ -f "$MODE_FILE" ]; then
  MODE="$(head -1 "$MODE_FILE" 2>/dev/null || true)"
  echo "🔊 playing: $MODE"
  if [ -f "$PID_FILE" ]; then
    echo "   pids: $(tr '\n' ' ' < "$PID_FILE")"
  fi
else
  echo "💤 silent"
fi

if [ -f "$POINTER" ]; then
  TRANSCRIPT="$(head -1 "$POINTER")"
  echo "   active session: $(basename "$(dirname "$TRANSCRIPT")")"
  echo "   transcript: $(basename "$TRANSCRIPT")"
fi
