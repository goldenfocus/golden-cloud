#!/bin/bash
# bella-speak-selection.sh — global "read selected text" hotkey.
# Uses a sentinel clipboard value so we can detect when ⌘C silently failed
# (permission issue, protected field, no selection active, etc.).
exec 2>>"$HOME/.claude/bella-tts/selection.log"
set -eu

STATE_DIR="$HOME/.claude/bella-tts"
mkdir -p "$STATE_DIR"
LOG() { echo "[$(date +%H:%M:%S)] $*"; }

# Save current clipboard so we can restore it after
OLD_CLIP="$(pbpaste 2>/dev/null || true)"
OLD_LEN=${#OLD_CLIP}

# Poison the clipboard with a unique sentinel — if ⌘C succeeds, pbpaste will
# return the new selection; if it fails, we'll still see the sentinel.
SENTINEL="__BELLA_SENTINEL_$$_$(date +%s)_$RANDOM__"
printf '%s' "$SENTINEL" | pbcopy

# Fire ⌘C in the focused app
/usr/bin/osascript -e 'tell application "System Events" to keystroke "c" using command down' >/dev/null 2>&1 || true

# Wait long enough for macOS to populate the pasteboard. Increased from 0.18 →
# 0.30 because larger selections and slower apps (Safari, PDF readers) need more time.
sleep 0.30

SELECTION="$(pbpaste 2>/dev/null || true)"

# Restore the user's original clipboard
printf '%s' "$OLD_CLIP" | pbcopy

# Diagnose the outcome
if [ "$SELECTION" = "$SENTINEL" ]; then
  LOG "⌘C did not change pasteboard — no selection, or automation permission denied"
  LOG "fix: System Settings → Privacy & Security → Automation → enable 'bash' or 'skhd' for System Events"
  # Subtle system feedback so user knows the hotkey fired but found nothing
  afplay /System/Library/Sounds/Funk.aiff >/dev/null 2>&1 &
  exit 0
fi

if [ -z "$SELECTION" ]; then
  LOG "selection was empty"
  exit 0
fi

LOG "captured ${#SELECTION} chars (prior clip: ${OLD_LEN} chars)"

# Kill any in-flight playback — user explicitly asked to hear THIS
if [ -f "$STATE_DIR/player.pid" ]; then
  while IFS= read -r pid; do
    [ -n "${pid:-}" ] && kill "$pid" 2>/dev/null || true
  done < "$STATE_DIR/player.pid"
fi
pkill -f "bella-player.py" 2>/dev/null || true
pkill -f "ffplay.*mp3" 2>/dev/null || true
rm -f "$STATE_DIR/player.pid" "$STATE_DIR/player.mode"

nohup /usr/bin/python3 "$HOME/.claude/hooks/bella-player.py" \
  --mode=say --text "$SELECTION" >/dev/null 2>&1 &
disown

LOG "launched player pid=$!"
exit 0
