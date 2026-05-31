#!/bin/bash
# play-audio-stop.sh — Claude Code Stop hook. Auto-narrates the finished turn
# when settings.auto is true. Instant + local; never blocks the turn.
set -uo pipefail
BASE="$HOME/.claude/local-tts"; PY="$BASE/xtts-venv/bin/python"
[ -x "$PY" ] || exit 0
auto=$("$PY" "$BASE/bin/pa-settings.py" get auto 2>/dev/null)
[ "$auto" = "True" ] || exit 0
payload=$(cat)
tx=$(printf '%s' "$payload" | "$PY" -c 'import json,sys;print(json.load(sys.stdin).get("transcript_path",""))' 2>/dev/null)
cwd=$(printf '%s' "$payload" | "$PY" -c 'import json,sys;print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null)
proj=$(basename "${cwd:-$PWD}")
[ -n "$tx" ] && [ -f "$tx" ] || exit 0
depth=$("$PY" "$BASE/bin/pa-settings.py" get defaultDepth)
text=$(GV_TRANSCRIPT="$tx" bash "$BASE/bin/gv-capture.sh" last)
[ -n "${text// /}" ] || exit 0
maxc=$("$PY" "$BASE/bin/pa-settings.py" get maxCharsBeforeCondense)
if [ "$depth" = "full" ] && [ "${#text}" -gt "${maxc:-1200}" ]; then depth=medium; fi
spoken=$(printf '%s' "$text" | bash "$BASE/bin/gv-depth.sh" "$depth")
[ -n "${spoken// /}" ] || exit 0
bash "$BASE/bin/gv-enqueue.sh" "$proj" "$spoken" >/dev/null
[ "${GV_NO_DRAIN:-0}" = "1" ] || (bash "$BASE/bin/gv-drain.sh" >/dev/null 2>&1 &)
exit 0
