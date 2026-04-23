#!/bin/bash
# bella-complete.sh — fires on Claude Code's Stop event.
# Updates session pointer, plays chime, kicks off a spoken recap,
# and pulses the firing Ghostty tab's title.
exec 2>>"$HOME/.claude/bella-tts/complete.log"
set -eu

STATE_DIR="$HOME/.claude/bella-tts"
mkdir -p "$STATE_DIR"

HOOK_JSON="$(cat)"
TRANSCRIPT=$(printf '%s' "$HOOK_JSON" | jq -r '.transcript_path // empty' 2>/dev/null || true)

# Skip sub-agent / plugin Stop events — only react to real user turns
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  LAST_LINE="$(tail -1 "$TRANSCRIPT" 2>/dev/null || true)"
  IS_SIDECHAIN=$(printf '%s' "$LAST_LINE" | jq -r '.isSidechain // false' 2>/dev/null || echo "false")
  if [ "$IS_SIDECHAIN" = "true" ]; then
    printf '{"continue":true,"suppressOutput":true}\n'
    exit 0
  fi
  printf '%s\n' "$TRANSCRIPT" > "$STATE_DIR/active-transcript"
fi

MODE_FILE="$STATE_DIR/player.mode"
CURRENT_MODE=""
[ -f "$MODE_FILE" ] && CURRENT_MODE="$(head -1 "$MODE_FILE" 2>/dev/null || true)"
if [ "$CURRENT_MODE" = "full" ]; then
  printf '{"continue":true,"suppressOutput":true}\n'
  exit 0
fi

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

CWD=$(printf '%s' "$HOOK_JSON" | jq -r '.cwd // empty' 2>/dev/null || true)
LABEL="$(basename "${CWD:-$PWD}" 2>/dev/null || echo "")"

TTY_ARGS=()
if TTY_PATH=$(find_parent_tty) && [ -n "$TTY_PATH" ] && [ -w "$TTY_PATH" ]; then
  TTY_ARGS=(--tty "$TTY_PATH" --label "$LABEL")
fi

(
  afplay /System/Library/Sounds/Tink.aiff >/dev/null 2>&1 || true
  sleep 0.25
  /usr/bin/python3 "$HOME/.claude/hooks/bella-player.py" --mode=recap "${TTY_ARGS[@]}" >/dev/null 2>&1 || true
) >/dev/null 2>&1 &
disown

printf '{"continue":true,"suppressOutput":true}\n'
exit 0
