#!/bin/bash
# golden-voice/install.sh — one-command installer for local, voice-cloned TTS.
#
# Sets up an on-device text-to-speech tool for Claude Code (and anything else):
#   - macOS `say` works instantly, zero install
#   - your own XTTS-v2 voice clone drops in with a one-variable flip
#
# Free forever, no API keys, no monthly bill. Idempotent — safe to re-run.
#
# Usage: bash blocks/golden-voice/install.sh
set -euo pipefail

BLOCK_DIR="$(cd "$(dirname "$0")" && pwd)"
TTS_DIR="$HOME/.claude/local-tts"
VENV_DIR="$TTS_DIR/xtts-venv"

echo "=== golden-voice — local, voice-cloned TTS ==="
echo

# --- prerequisites ---
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "error: macOS only (uses CoreAudio, say, afplay)" >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "error: Homebrew not found. Install it from https://brew.sh then re-run." >&2
  exit 1
fi

# sox powers clean recording + optional effects; recommend (don't hard-fail).
if ! command -v sox >/dev/null 2>&1; then
  echo "note: 'sox' not found — installing (clean CoreAudio capture + effects)..."
  brew install sox || echo "warning: 'brew install sox' failed; recording will fall back to ffmpeg." >&2
fi

# --- copy the tool into place ---
mkdir -p "$TTS_DIR"
cp "$BLOCK_DIR/local-tts.sh"   "$TTS_DIR/local-tts.sh"
cp "$BLOCK_DIR/record-voice.sh" "$TTS_DIR/record-voice.sh"
cp "$BLOCK_DIR/XTTS-LATER.md"  "$TTS_DIR/XTTS-LATER.md"
chmod +x "$TTS_DIR/local-tts.sh" "$TTS_DIR/record-voice.sh"
echo "installed scripts to $TTS_DIR"

# --- seed config from the template (never clobber an existing config) ---
if [ ! -f "$TTS_DIR/config.env" ]; then
  cp "$BLOCK_DIR/config.env.example" "$TTS_DIR/config.env"
  echo "seeded $TTS_DIR/config.env (defaults to the macOS 'say' backend)"
else
  echo "config.env already present — keeping it"
fi

# --- Python 3.11 venv + coqui-tts (the XTTS engine) ---
# macOS system Python is 3.9; XTTS-v2 wants 3.11.
if ! command -v python3.11 >/dev/null 2>&1; then
  echo "installing python@3.11 via brew (XTTS needs it; system python is 3.9)..."
  brew install python@3.11
fi

if [ ! -x "$VENV_DIR/bin/tts" ]; then
  echo "creating XTTS venv at $VENV_DIR ..."
  python3.11 -m venv "$VENV_DIR"
  echo "installing coqui-tts (this pulls torch — a few minutes the first time)..."
  "$VENV_DIR/bin/pip" install --quiet --upgrade pip
  "$VENV_DIR/bin/pip" install coqui-tts
  echo "XTTS engine ready: $VENV_DIR/bin/tts"
else
  echo "XTTS venv already present — keeping it"
fi

# --- smoke test the instant backend ---
echo
echo "testing the 'say' backend..."
"$TTS_DIR/local-tts.sh" --test 2>/dev/null || true

cat <<DONE

=== done ===

Two backends, one pipeline:
  - say  (default) → macOS built-in voice, works right now
  - xtts (later)   → YOUR voice, cloned locally, free, no API keys

Speak something:
  $TTS_DIR/local-tts.sh "hello from my own machine"
  echo "piped text" | $TTS_DIR/local-tts.sh

To use YOUR voice (the whole point):
  1. Record 15-30s of yourself talking naturally:
       $TTS_DIR/record-voice.sh
     (saves to $TTS_DIR/my-voice.wav — stays on YOUR machine, never committed)
  2. Flip the backend in $TTS_DIR/config.env:
       LOCAL_TTS_BACKEND=xtts
  3. Speak in your voice:
       $TTS_DIR/local-tts.sh --test

First xtts run downloads the ~1.8GB XTTS-v2 model once. See $TTS_DIR/XTTS-LATER.md.
DONE
