#!/bin/bash
# local-tts.sh — pluggable local text-to-speech for Claude narration.
#
# Goal: speak text on-device, free, no API keys. Backend is swappable so today's
# stock macOS voice can be replaced by your own XTTS voice clone later with a
# one-variable flip — same pipeline, nothing else changes.
#
#   BACKEND=say   (default) → macOS `say`, instant, zero install
#   BACKEND=xtts  (later)   → Coqui XTTS-v2 with your 15-30s cloned voice sample
#
# Usage:
#   local-tts.sh "some text to speak"
#   echo "piped text" | local-tts.sh
#   local-tts.sh --test
#
# Config via env (or ~/.claude/local-tts/config.env if present):
#   LOCAL_TTS_BACKEND      say | xtts          (default: say)
#   LOCAL_TTS_VOICE        a `say` voice name  (default: best installed, see list)
#   LOCAL_TTS_RATE         words-per-minute    (default: 180)
#   LOCAL_TTS_EFFECTS      sox effect chain    (default: none, e.g. "reverb 30")
#   LOCAL_TTS_SPEAKER_WAV  path to your voice clone sample (xtts backend only)

set -uo pipefail

CFG="$HOME/.claude/local-tts/config.env"
[ -f "$CFG" ] && . "$CFG"

BACKEND="${LOCAL_TTS_BACKEND:-say}"
RATE="${LOCAL_TTS_RATE:-180}"
EFFECTS="${LOCAL_TTS_EFFECTS:-}"

# --- gather text (arg(s) or stdin) ---
if [ "${1:-}" = "--test" ]; then
  TEXT="Local voice is live. No cloud, no API keys, no monthly bill. Your cloned voice drops in right here, later."
elif [ "$#" -gt 0 ]; then
  TEXT="$*"
else
  TEXT="$(cat)"
fi
[ -z "${TEXT// /}" ] && { echo "[local-tts] nothing to speak" >&2; exit 0; }

# --- pick the best installed macOS voice if none specified ---
pick_say_voice() {
  [ -n "${LOCAL_TTS_VOICE:-}" ] && { printf '%s' "$LOCAL_TTS_VOICE"; return; }
  local installed; installed="$(say -v '?' 2>/dev/null)"
  local v
  for v in "Ava (Premium)" "Zoe (Premium)" "Ava (Enhanced)" "Allison" "Samantha" "Tom" "Aaron" "Daniel"; do
    printf '%s\n' "$installed" | grep -Fq "$v " && { printf '%s' "$v"; return; }
  done
  printf '%s' ""   # system default voice
}

case "$BACKEND" in
  say)
    VOICE="$(pick_say_voice)"
    VOPT=(); [ -n "$VOICE" ] && VOPT=(-v "$VOICE")
    if [ -n "$EFFECTS" ] && command -v sox >/dev/null 2>&1; then
      tmp="$(mktemp).aiff"
      say "${VOPT[@]}" -r "$RATE" -o "$tmp" "$TEXT" && sox "$tmp" -d $EFFECTS 2>/dev/null
      rm -f "$tmp"
    else
      say "${VOPT[@]}" -r "$RATE" "$TEXT"
    fi
    ;;

  xtts)
    BASE="$HOME/.claude/local-tts"
    # --- speaker wavs from the active voice profile (multi-sample average), with fallbacks ---
    PROFILE="${LOCAL_TTS_VOICE_PROFILE:-me}"
    SDIR="$BASE/voices/$PROFILE/samples"
    spk=()
    if compgen -G "$SDIR/*.wav" >/dev/null 2>&1; then
      for f in "$SDIR"/*.wav; do spk+=("$f"); done
    elif compgen -G "$BASE/samples/*.wav" >/dev/null 2>&1; then          # legacy flat samples/
      for f in "$BASE/samples"/*.wav; do spk+=("$f"); done
    else
      spk=("${LOCAL_TTS_SPEAKER_WAV:-$BASE/my-voice.wav}")
    fi
    [ -f "${spk[0]}" ] || { echo "[local-tts] no voice sample — record one: gv record" >&2; exit 3; }

    # --- fx preset (sox chain applied after synth) ---
    FX_PRESET="${LOCAL_TTS_FX:-$("$BASE/xtts-venv/bin/python" "$BASE/bin/pa-settings.py" get fxPreset 2>/dev/null)}"
    case "$FX_PRESET" in
      warm)   FX="bass +3 gain -1" ;;
      reverb) FX="reverb 22 gain -1" ;;
      echo)   FX="echo 0.8 0.9 120 0.4" ;;
      *)      FX="" ;;
    esac
    # per-voice pitch (cents) from voice.json, if present
    VJSON="$BASE/voices/$PROFILE/voice.json"
    if [ -f "$VJSON" ]; then
      PITCH=$("$BASE/xtts-venv/bin/python" -c "import json,sys;print(json.load(open('$VJSON')).get('pitch',0))" 2>/dev/null)
      [ -n "${PITCH:-}" ] && [ "$PITCH" != "0" ] && FX="pitch $PITCH $FX"
    fi

    # --- content-addressed cache (voice content + fx + text) ---
    CACHE_DIR="$BASE/cache"; mkdir -p "$CACHE_DIR"
    spk_sig=$(stat -f '%N:%z:%m' "${spk[@]}" 2>/dev/null | shasum -a 256 | cut -c1-12)
    key=$(printf 'xtts|%s|%s|%s' "$spk_sig" "$FX" "$TEXT" | shasum -a 256 | cut -c1-16)
    cached="$CACHE_DIR/$key.wav"

    if [ "${LOCAL_TTS_NOCACHE:-0}" = "1" ] || [ ! -s "$cached" ]; then
      raw="$cached"; [ -n "$FX" ] && raw="$(mktemp).wav"
      PY="$BASE/xtts-venv/bin/python"
      jstr() { printf '%s' "$1" | "$PY" -c 'import sys,json;print(json.dumps(sys.stdin.read()))'; }
      spk_json=$(printf '%s\n' "${spk[@]}" | "$PY" -c "import sys,json;print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))")
      daemon_up=0; curl -sf -m 2 http://127.0.0.1:5111/health >/dev/null 2>&1 && daemon_up=1
      TTS_BIN="${LOCAL_TTS_XTTS_BIN:-$BASE/xtts-venv/bin/tts}"
      # XTTS-v2 garbles/truncates past ~250 chars/call — split into safe chunks,
      # synth each (daemon fast-path or CLI fallback), then concatenate with sox.
      parts=()
      while IFS= read -r chunk; do
        [ -n "${chunk// /}" ] || continue
        part="$(mktemp).wav"
        if [ "$daemon_up" = 1 ]; then
          curl -sf -m 120 -X POST http://127.0.0.1:5111/synth -H 'Content-Type: application/json' \
            -d "$(printf '{"text":%s,"speaker_wavs":%s,"language":"en","out":%s}' \
                  "$(jstr "$chunk")" "$spk_json" "$(jstr "$part")")" >/dev/null
        else
          COQUI_TOS_AGREED=1 "$TTS_BIN" --model_name "tts_models/multilingual/multi-dataset/xtts_v2" \
            --speaker_wav "${spk[@]}" --language_idx en --text "$chunk" --out_path "$part" >/dev/null 2>&1
        fi
        [ -s "$part" ] && parts+=("$part") || rm -f "$part"
      done < <("$PY" "$BASE/bin/chunk_text.py" "$TEXT")
      # assemble synthesized parts into $raw
      if [ "${#parts[@]}" -eq 1 ]; then
        mv "${parts[0]}" "$raw"
      elif [ "${#parts[@]}" -gt 1 ]; then
        sox "${parts[@]}" "$raw" 2>/dev/null; rm -f "${parts[@]}"
      fi
      if [ -n "$FX" ] && [ -s "$raw" ]; then sox "$raw" "$cached" $FX 2>/dev/null; rm -f "$raw"; fi
      [ -s "$cached" ] && printf '%s\t%s\n' "$key" "$TEXT" >> "$CACHE_DIR/index.tsv"
    fi

    [ -s "$cached" ] || { echo "[local-tts] xtts produced no audio" >&2; exit 1; }

    if [ "${LOCAL_TTS_NOPLAY:-0}" = "1" ]; then
      printf '%s\n' "$cached"          # emit the path for callers (player/export)
    elif command -v mpv >/dev/null 2>&1; then
      mpv --no-video --really-quiet "$cached"
    else
      afplay "$cached"
    fi
    ;;

  *)
    echo "[local-tts] unknown backend '$BACKEND' (use: say | xtts)" >&2
    exit 2
    ;;
esac
