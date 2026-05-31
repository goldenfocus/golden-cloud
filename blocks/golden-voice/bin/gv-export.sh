#!/bin/bash
# gv-export.sh <name> <text> — synth + normalize to -16 LUFS + encode wav/opus/mp3 + manifest.
set -uo pipefail
BASE="$HOME/.claude/local-tts"; PY="$BASE/xtts-venv/bin/python"
NAME="${1:?name}"; TEXT="${2:?text}"
VOICE=$("$PY" "$BASE/bin/pa-settings.py" get voice)
FX=$("$PY" "$BASE/bin/pa-settings.py" get fxPreset)
raw=$(LOCAL_TTS_BACKEND=xtts LOCAL_TTS_NOPLAY=1 LOCAL_TTS_VOICE_PROFILE="$VOICE" bash "$BASE/local-tts.sh" "$TEXT")
[ -s "$raw" ] || { echo "[gv-export] synth failed" >&2; exit 1; }
d="$BASE/library/$NAME"; mkdir -p "$d"
wav="$d/$NAME.wav"; opus="$d/$NAME.opus"; mp3="$d/$NAME.mp3"
# loudness-normalize to -16 LUFS (master), then encode delivery formats
ffmpeg -y -i "$raw" -af loudnorm=I=-16:TP=-1.5:LRA=11 -ar 24000 -ac 1 "$wav" >/dev/null 2>&1
ffmpeg -y -i "$wav" -c:a libopus -b:a 28k -ac 1 "$opus" >/dev/null 2>&1
ffmpeg -y -i "$wav" -c:a libmp3lame -q:a 5 -ac 1 "$mp3" >/dev/null 2>&1
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$wav" 2>/dev/null)
lufs=$(ffmpeg -i "$wav" -af loudnorm=print_format=json -f null - 2>&1 | "$PY" -c 'import sys,re,json;m=re.findall(r"\{[^{}]*input_i[^{}]*\}",sys.stdin.read());print(json.loads(m[-1])["input_i"] if m else "")' 2>/dev/null)
# append/replace manifest entry
"$PY" - "$BASE/library/manifest.json" "$NAME" "$TEXT" "$VOICE" "$FX" "$dur" "$lufs" "$wav" "$opus" "$mp3" <<'PY'
import json,os,sys,datetime
mf,name,text,voice,fx,dur,lufs,wav,opus,mp3=sys.argv[1:11]
data=[]
if os.path.exists(mf):
    try: data=json.load(open(mf))
    except: data=[]
data=[e for e in data if e.get("id")!=name]
data.append({"id":name,"text":text,"voice":voice,"fx":fx,
  "durationMs":int(float(dur)*1000) if dur else None,
  "lufs":float(lufs) if lufs else None,
  "files":{"wav":wav,"opus":opus,"mp3":mp3},
  "createdISO":datetime.datetime.now().astimezone().isoformat()})
json.dump(data,open(mf,"w"),indent=2)
PY
echo "🎚️  exported library/$NAME  (wav+opus+mp3)"
