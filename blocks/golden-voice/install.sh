#!/bin/bash
# golden-voice/install.sh — one-command installer for local, voice-cloned TTS
# with terminal listen-mode (resident daemon, fx, queue, mpv controls, export).
#
# Free forever, no API keys, no monthly bill. Idempotent — safe to re-run.
#
# Usage: bash blocks/golden-voice/install.sh
set -euo pipefail

BLOCK_DIR="$(cd "$(dirname "$0")" && pwd)"
TTS_DIR="$HOME/.claude/local-tts"
VENV_DIR="$TTS_DIR/xtts-venv"

echo "=== golden-voice — local, voice-cloned TTS + terminal listen-mode ==="
echo

# --- prerequisites ---
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "error: macOS only (uses CoreAudio, say, mpv, afplay)" >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "error: Homebrew not found. Install it from https://brew.sh then re-run." >&2
  exit 1
fi

# sox  → clean CoreAudio recording + fx chains
# mpv  → playback engine with live IPC controls (pause / ff / 2x / stop)
# ffmpeg → loudness-normalization + Opus/MP3 encoding for exports
for tool in sox mpv ffmpeg; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "note: '$tool' not found — installing..."
    brew install "$tool" || echo "warning: 'brew install $tool' failed." >&2
  fi
done

# --- copy the tool into place ---
mkdir -p "$TTS_DIR" "$TTS_DIR/bin"
cp "$BLOCK_DIR/local-tts.sh"                   "$TTS_DIR/local-tts.sh"
cp "$BLOCK_DIR/record-voice.sh"                "$TTS_DIR/record-voice.sh"
cp "$BLOCK_DIR/tts-daemon.sh"                  "$TTS_DIR/tts-daemon.sh"
cp "$BLOCK_DIR/com.goldenvoice.tts-daemon.plist" "$TTS_DIR/com.goldenvoice.tts-daemon.plist"
cp "$BLOCK_DIR/XTTS-LATER.md"                  "$TTS_DIR/XTTS-LATER.md"
cp "$BLOCK_DIR"/bin/*.sh "$BLOCK_DIR"/bin/*.py "$TTS_DIR/bin/"
chmod +x "$TTS_DIR/local-tts.sh" "$TTS_DIR/record-voice.sh" "$TTS_DIR/tts-daemon.sh" \
         "$TTS_DIR"/bin/*.sh
echo "installed scripts to $TTS_DIR (+ bin/)"

# --- install the `gv` fish command ---
if [ -f "$BLOCK_DIR/gv.fish" ] && command -v fish >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/fish/functions"
  cp "$BLOCK_DIR/gv.fish" "$HOME/.config/fish/functions/gv.fish"
  echo "installed 'gv' fish command — run 'gv' for the cheat sheet"
elif [ -f "$BLOCK_DIR/gv.fish" ]; then
  echo "note: fish not found — skipped 'gv' (install fish, then copy gv.fish to ~/.config/fish/functions/)"
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
  # Guard on a working pip, not just the dir: an interrupted or concurrent run
  # can leave $VENV_DIR present but pip-less, which would crash the next line.
  [ -x "$VENV_DIR/bin/pip" ] || python3.11 -m venv "$VENV_DIR"
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

Next steps:

  1. Record your voice (more clips = a better clone):
       gv record
     (saves under $TTS_DIR/voices/me/samples/ — stays on YOUR machine, never committed)

  2. Start the resident daemon (model loads once ~20s, then synth ~2s):
       bash $TTS_DIR/tts-daemon.sh start

  3. Speak in your voice:
       gv say "hello from my own machine"

  Live controls while it's talking:  gv pause · gv ff · gv x2 · gv stop

Optional — autostart the daemon at login (launchd):
  sed "s#__HOME__#\$HOME#g" $TTS_DIR/com.goldenvoice.tts-daemon.plist \\
    > ~/Library/LaunchAgents/com.goldenvoice.tts-daemon.plist
  launchctl load ~/Library/LaunchAgents/com.goldenvoice.tts-daemon.plist

Optional — Claude Code integration (manual; the installer won't touch your settings):
  - Skill:  cp $BLOCK_DIR/claude-assets/play-audio.md  ~/.claude/commands/
  - Hook:   cp $BLOCK_DIR/claude-assets/play-audio-stop.sh ~/.claude/hooks/
            then register it as a Stop hook in ~/.claude/settings.json and
            opt in with 'gv auto on'  (auto-narration is OFF by default).
  See README.md → "Claude Code integration" for the exact snippet.

Speed notes:
  - Identical phrases are content-cached → repeats are instant.
  - First synth downloads the ~1.8GB XTTS-v2 model once.
  - The resident daemon removes the ~20s cold-load from every subsequent call.

See $TTS_DIR/XTTS-LATER.md and README.md for details.
DONE
