#!/bin/bash
# gv-drain.sh — become the single drainer (mkdir lock); play pending items FIFO,
# announcing "Project X." when the project changes. GV_DRY_RUN=1 prints instead.
set -uo pipefail
BASE="$HOME/.claude/local-tts"; Q="$BASE/queue"; PEND="$Q/pending"; LOCK="$Q/lock"
mkdir -p "$PEND"
mkdir "$LOCK" 2>/dev/null || exit 0          # someone else is draining
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
PY="$BASE/xtts-venv/bin/python"
last_proj=""
announce=$("$PY" "$BASE/bin/pa-settings.py" get announceProject)
while :; do
  next=$(ls "$PEND"/*.json 2>/dev/null | sort | head -1)
  [ -z "$next" ] && break
  proj=$("$PY" -c "import json,sys;print(json.load(open(sys.argv[1]))['project'])" "$next")
  text=$("$PY" -c "import json,sys;print(json.load(open(sys.argv[1]))['text'])" "$next")
  voice=$("$PY" -c "import json,sys;print(json.load(open(sys.argv[1]))['voice'])" "$next")
  rm -f "$next"
  if [ "$announce" = "True" ] && [ "$proj" != "$last_proj" ]; then
    if [ "${GV_DRY_RUN:-0}" = "1" ]; then echo "ANNOUNCE $proj"
    else LOCAL_TTS_BACKEND=xtts LOCAL_TTS_VOICE_PROFILE="$voice" bash "$BASE/local-tts.sh" "Project $proj."; fi
  fi
  last_proj="$proj"
  if [ "${GV_DRY_RUN:-0}" = "1" ]; then echo "PLAY [$proj] $text"
  else
    wav=$(LOCAL_TTS_BACKEND=xtts LOCAL_TTS_NOPLAY=1 LOCAL_TTS_VOICE_PROFILE="$voice" bash "$BASE/local-tts.sh" "$text")
    [ -s "$wav" ] && bash "$BASE/bin/gv-play.sh" "$wav"
  fi
done
