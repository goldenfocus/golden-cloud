#!/bin/bash
# bella-pointer.sh — Claude Code hook.
# Writes the active USER session's transcript_path to the pointer file.
# Skips sub-agent / plugin sessions (detected via isSidechain in the transcript).
exec 2>>"$HOME/.claude/bella-tts/pointer.log"
set -eu

STATE_DIR="$HOME/.claude/bella-tts"
mkdir -p "$STATE_DIR"

HOOK_JSON="$(cat)"
TRANSCRIPT=$(printf '%s' "$HOOK_JSON" | jq -r '.transcript_path // empty' 2>/dev/null || true)

if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # Skip sidechain (plugin sub-agent) sessions — only track real user turns
  LAST_LINE="$(tail -1 "$TRANSCRIPT" 2>/dev/null || true)"
  IS_SIDECHAIN=$(printf '%s' "$LAST_LINE" | jq -r '.isSidechain // false' 2>/dev/null || echo "false")
  if [ "$IS_SIDECHAIN" != "true" ]; then
    printf '%s\n' "$TRANSCRIPT" > "$STATE_DIR/active-transcript"
  fi
fi

printf '{"continue":true,"suppressOutput":true}\n'
exit 0
