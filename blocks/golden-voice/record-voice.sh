#!/bin/bash
# record-voice.sh — capture a voice sample for XTTS cloning.
# ~30s, mono, 22.05kHz wav. Spoken 3-2-1 cue so timing works by ear.
#
#   ~/.claude/local-tts/record-voice.sh           # 30s to ~/.claude/local-tts/my-voice.wav
#   SECS=20 MIC=0 OUT=/tmp/take2.wav  ~/.claude/local-tts/record-voice.sh
set -uo pipefail
OUT="${OUT:-$HOME/.claude/local-tts/my-voice.wav}"
MIC="${MIC:-0}"            # avfoundation audio device index (0 = MacBook Pro Microphone)
SECS="${SECS:-30}"
mkdir -p "$(dirname "$OUT")"

say "Recording in 3"; say "2"; say "1"; say "Go. Talk naturally."
ENGINE="${ENGINE:-sox}"
if [ "$ENGINE" = "sox" ] && command -v sox >/dev/null 2>&1; then
  # sox → CoreAudio capture: glitch-free where ffmpeg-avfoundation crackled ("electricity").
  # Native 48k/24-bit, transparent highpass + peak-normalize. WAV stays uncompressed (~1.1 Mbps).
  sox -t coreaudio default -b 24 "$OUT" trim 0 "$SECS" highpass 70 gain -n -1.5
else
  # Fallback engine: ffmpeg avfoundation raw + sox post.
  TMP="$(mktemp).wav"
  ffmpeg -y -hide_banner -loglevel error -thread_queue_size 1024 -f avfoundation -i ":$MIC" \
    -t "$SECS" -c:a pcm_s24le "$TMP"
  sox "$TMP" "$OUT" highpass 70 gain -n -1.5 2>/dev/null && rm -f "$TMP" || mv "$TMP" "$OUT"
fi
say "Stop. Captured."

dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT" 2>/dev/null)
sz=$(stat -f%z "$OUT" 2>/dev/null)
echo "saved: $OUT  (${dur}s, ${sz} bytes)"
