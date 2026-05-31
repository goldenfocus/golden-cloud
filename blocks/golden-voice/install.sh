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

# sox powers clean CoreAudio recording + optional effects; ffmpeg for playback/levels.
for tool in sox ffmpeg; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "note: '$tool' not found — installing..."
    brew install "$tool" || echo "warning: 'brew install $tool' failed." >&2
  fi
done

# --- copy the tool into place ---
mkdir -p "$TTS_DIR"
cp "$BLOCK_DIR/local-tts.sh"    "$TTS_DIR/local-tts.sh"
cp "$BLOCK_DIR/record-voice.sh" "$TTS_DIR/record-voice.sh"
cp "$BLOCK_DIR/XTTS-LATER.md"   "$TTS_DIR/XTTS-LATER.md"
chmod +x "$TTS_DIR/local-tts.sh" "$TTS_DIR/record-voice.sh"
echo "installed scripts to $TTS_DIR"

# --- optional: install the `gv` fish convenience command ---
if [ -f "$BLOCK_DIR/gv.fish" ] && command -v fish >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/fish/functions"
  cp "$BLOCK_DIR/gv.fish" "$HOME/.config/fish/functions/gv.fish"
  echo "installed 'gv' fish command (gv say \"...\" · gv save <name> \"...\" · gv <name>)"
fi

# --- seed config from the template (never clobber an existing config) ---
if [ ! -f "$TTS_DIR/config.env" ]; then
  cp "$BLOCK_DIR/config.env.example" "$TTS_DIR/config.env"
  echo "seeded $TTS_DIR/config.env (defaults to the macOS 'say' backend)"
else
  echo "config.env already present — keeping it"
fi

# --- Python 3.11 venv + the FULL XTTS stack ---
# macOS system Python is 3.9; XTTS-v2 wants 3.11.
if ! command -v python3.11 >/dev/null 2>&1; then
  echo "installing python@3.11 via brew (XTTS needs it; system python is 3.9)..."
  brew install python@3.11
fi

# coqui-tts does NOT bundle torch/torchcodec, and pins nothing on transformers —
# all four pieces are required or the `tts` CLI breaks on import:
#   * torch + torchaudio        — the engine
#   * transformers >=4.43,<5    — 5.x removed isin_mps_friendly (ImportError)
#   * coqui-tts[codec]          — torchcodec, required for audio IO on torch >=2.9
if ! "$VENV_DIR/bin/tts" --help >/dev/null 2>&1; then
  echo "setting up the XTTS engine (first time pulls torch — a few minutes)..."
  [ -d "$VENV_DIR" ] || python3.11 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/pip" install --quiet --upgrade pip
  "$VENV_DIR/bin/pip" install --quiet \
    'coqui-tts[codec]' \
    torch torchaudio \
    'transformers>=4.43,<5'
  if "$VENV_DIR/bin/tts" --help >/dev/null 2>&1; then
    echo "XTTS engine ready: $VENV_DIR/bin/tts"
  else
    echo "warning: XTTS CLI still not importing — inspect the pip output above." >&2
  fi
else
  echo "XTTS engine already working — keeping it"
fi

# --- smoke test the instant backend ---
echo
echo "testing the 'say' backend..."
LOCAL_TTS_BACKEND=say "$TTS_DIR/local-tts.sh" --test 2>/dev/null || true

cat <<DONE

=== done ===

Two backends, one pipeline:
  - say  (default) → macOS built-in voice, works right now
  - xtts            → YOUR voice, cloned locally, free, no API keys

Speak something:
  $TTS_DIR/local-tts.sh "hello from my own machine"
  gv say "hello from my own machine"          # if you use fish

To use YOUR voice (the whole point):
  1. Record 15-30s of yourself talking naturally:
       $TTS_DIR/record-voice.sh
     (saves to $TTS_DIR/my-voice.wav — stays on YOUR machine, never committed)
  2. Flip the backend in $TTS_DIR/config.env:
       LOCAL_TTS_BACKEND=xtts
  3. Speak in your voice:
       $TTS_DIR/local-tts.sh --test

Speed notes:
  - Identical phrases are cached (~/.claude/local-tts/cache) → repeats are instant.
  - First xtts run downloads the ~1.8GB XTTS-v2 model once.
  - A brand-new phrase costs ~20s of model cold-load; a resident tts-server removes that.

Reusable named clips (great for hooks):
  gv save push-done "Pushed clean. Another one in the bag."
  gv push-done        # instant, anywhere

See $TTS_DIR/XTTS-LATER.md for details.
DONE
