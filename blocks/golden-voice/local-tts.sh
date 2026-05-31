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
    # --- your own cloned voice, fully local via Coqui XTTS-v2 (installed in a venv) ---
    TTS_BIN="${LOCAL_TTS_XTTS_BIN:-$HOME/.claude/local-tts/xtts-venv/bin/tts}"
    if [ ! -x "$TTS_BIN" ]; then
      echo "[local-tts] xtts not installed — see ~/.claude/local-tts/XTTS-LATER.md" >&2
      exit 3
    fi
    SPK="${LOCAL_TTS_SPEAKER_WAV:-$HOME/.claude/local-tts/my-voice.wav}"
    [ -f "$SPK" ] || { echo "[local-tts] no voice sample at $SPK (record one: record-voice.sh)" >&2; exit 3; }
    out="$(mktemp).wav"
    # COQUI_TOS_AGREED accepts the model license non-interactively. First run pulls ~1.8GB.
    COQUI_TOS_AGREED=1 "$TTS_BIN" \
      --model_name "tts_models/multilingual/multi-dataset/xtts_v2" \
      --speaker_wav "$SPK" --language_idx en \
      --text "$TEXT" --out_path "$out" >/dev/null 2>&1
    if [ -s "$out" ]; then
      if command -v ffplay >/dev/null 2>&1; then ffplay -autoexit -nodisp -loglevel quiet "$out"
      else afplay "$out"; fi
    else
      echo "[local-tts] xtts produced no audio (first run still downloading the ~1.8GB model?)" >&2
    fi
    rm -f "$out"
    ;;

  *)
    echo "[local-tts] unknown backend '$BACKEND' (use: say | xtts)" >&2
    exit 2
    ;;
esac
