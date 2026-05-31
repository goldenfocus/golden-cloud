#!/bin/bash
# gv-play.sh <wav> — play a wav via mpv with an IPC socket so gv-ctl can drive it.
set -uo pipefail
BASE="$HOME/.claude/local-tts"; SOCK="$BASE/queue/mpv.sock"
SPEED=$("$BASE/xtts-venv/bin/python" "$BASE/bin/pa-settings.py" get speed)
rm -f "$SOCK"
exec mpv --no-video --really-quiet --input-ipc-server="$SOCK" --speed="${SPEED:-1.0}" "$1"
