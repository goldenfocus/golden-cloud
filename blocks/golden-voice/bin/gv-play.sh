#!/bin/bash
# gv-play.sh <wav> — play a wav via mpv with an IPC socket so gv-ctl can drive it.
set -uo pipefail
BASE="$HOME/.claude/local-tts"; SOCK="$BASE/queue/mpv.sock"
SPEED=$("$BASE/xtts-venv/bin/python" "$BASE/bin/pa-settings.py" get speed)
rm -f "$SOCK"
# Prefer mpv (live pause/ff/x2 via the IPC socket). Fall back to afplay — always
# present on macOS — so playback still works if mpv isn't installed (no controls).
if command -v mpv >/dev/null 2>&1; then
  exec mpv --no-video --really-quiet --input-ipc-server="$SOCK" --speed="${SPEED:-1.0}" "$1"
else
  echo "note: mpv not found — playing via afplay (no pause/ff/x2 controls). 'brew install mpv' to enable them." >&2
  exec afplay "$1"
fi
