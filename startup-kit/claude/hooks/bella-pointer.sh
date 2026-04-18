#!/bin/bash
# bella-pointer.sh — Claude Code hook.
# Runs on UserPromptSubmit and Stop. Writes the active session's transcript_path
# to ~/.claude/bella-tts/active-transcript so the hotkey knows which JSONL to read.
# Silent; never blocks the turn.

exec 2>>"$HOME/.claude/bella-tts/pointer.log"
set -eu

STATE_DIR="$HOME/.claude/bella-tts"
mkdir -p "$STATE_DIR"

HOOK_JSON="$(cat)"
TRANSCRIPT=$(printf '%s' "$HOOK_JSON" | jq -r '.transcript_path // empty' 2>/dev/null || true)

if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  printf '%s\n' "$TRANSCRIPT" > "$STATE_DIR/active-transcript"
fi

# Always pass-through — don't block the turn
printf '{"continue":true,"suppressOutput":true}\n'
exit 0
