#!/bin/bash
# gv-enqueue.sh <project> <text> [voice] — drop a playback item; ordered by ns timestamp.
set -uo pipefail
BASE="$HOME/.claude/local-tts"; PEND="$BASE/queue/pending"; mkdir -p "$PEND"
PROJ="${1:?project}"; TEXT="${2:?text}"; VOICE="${3:-$("$BASE/xtts-venv/bin/python" "$BASE/bin/pa-settings.py" get voice)}"
ns=$("$BASE/xtts-venv/bin/python" -c 'import time;print(time.time_ns())')
f="$PEND/$ns-$$.json"
"$BASE/xtts-venv/bin/python" - "$f" "$PROJ" "$TEXT" "$VOICE" <<'PY'
import json,sys
f,proj,text,voice=sys.argv[1:5]
json.dump({"project":proj,"text":text,"voice":voice}, open(f,"w"))
PY
echo "$f"
