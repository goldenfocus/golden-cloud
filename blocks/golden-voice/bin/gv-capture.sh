#!/bin/bash
# gv-capture.sh {clip|last} — emit source text.
#   clip  -> system clipboard (pbpaste)
#   last  -> newest assistant text block from the session transcript ($GV_TRANSCRIPT)
set -uo pipefail
BASE="$HOME/.claude/local-tts"; PY="$BASE/xtts-venv/bin/python"
case "${1:-clip}" in
  clip) pbpaste ;;
  last)
    TX="${GV_TRANSCRIPT:-}"
    [ -n "$TX" ] && [ -f "$TX" ] || { echo "" ; exit 0; }
    "$PY" - "$TX" <<'PY'
import json,sys
last=""
for line in open(sys.argv[1]):
    line=line.strip()
    if not line: continue
    try: o=json.loads(line)
    except: continue
    if o.get("type")!="assistant": continue
    msg=o.get("message",{})
    parts=msg.get("content",[])
    if isinstance(parts,str):
        last=parts; continue
    txt="".join(p.get("text","") for p in parts if isinstance(p,dict) and p.get("type")=="text")
    if txt.strip(): last=txt
sys.stdout.write(last.strip())
PY
    ;;
  *) echo "usage: gv-capture.sh {clip|last}"; exit 2 ;;
esac
