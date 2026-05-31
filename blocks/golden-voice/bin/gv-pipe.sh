#!/bin/bash
# gv-pipe.sh <source clip|last> <depth full|medium|recap> [project]
# The one path both `gv play` and the /play-audio skill call.
set -uo pipefail
BASE="$HOME/.claude/local-tts"
SRC="${1:-clip}"; DEPTH="${2:-$("$BASE/xtts-venv/bin/python" "$BASE/bin/pa-settings.py" get defaultDepth)}"
PROJ="${3:-$(basename "$PWD")}"
if [ -n "${GV_FORCE_TEXT:-}" ]; then raw="$GV_FORCE_TEXT"; else raw=$(bash "$BASE/bin/gv-capture.sh" "$SRC"); fi
[ -n "${raw// /}" ] || { echo "[gv] nothing to read" >&2; exit 0; }
spoken=$(printf '%s' "$raw" | bash "$BASE/bin/gv-depth.sh" "$DEPTH")
[ -n "${spoken// /}" ] || exit 0
bash "$BASE/bin/gv-enqueue.sh" "$PROJ" "$spoken" >/dev/null
[ "${GV_NO_DRAIN:-0}" = "1" ] || bash "$BASE/bin/gv-drain.sh" &
