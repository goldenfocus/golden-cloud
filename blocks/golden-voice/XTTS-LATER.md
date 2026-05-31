# Cloning your voice (XTTS-v2)

The scaffold (`local-tts.sh`) already speaks via macOS `say`. When you're ready to
swap in **your own voice**, nothing in the pipeline changes except the backend.

> `install.sh` already runs steps 1–2 below (the Python 3.11 venv + `coqui-tts`).
> This file is the manual reference if you want to do it by hand or troubleshoot.

## 1. Record a sample (15–30s)
Talk naturally — a paragraph of normal speech, quiet room, no music.
```bash
# Preferred: sox/CoreAudio native capture (clean on Apple hardware).
~/.claude/local-tts/record-voice.sh
# saves to ~/.claude/local-tts/my-voice.wav
```

> **Recording gotcha (learned the hard way):** on Apple hardware, capturing through
> `ffmpeg -f avfoundation` produced a buzzy/"electrical" hum, and resampling /
> `loudnorm` only made it worse. The clean fix was native **sox/CoreAudio** capture
> at 48k/24-bit with only `highpass 70 gain -n -1.5` — no resampling, no loudnorm.
> `record-voice.sh` does exactly this; ffmpeg is only a labelled fallback.

## 2. Install the engine (one-time, ~1.8GB model on first run)
System Python is 3.9; XTTS wants 3.11.
```bash
brew install python@3.11
python3.11 -m venv ~/.claude/local-tts/xtts-venv
~/.claude/local-tts/xtts-venv/bin/pip install coqui-tts   # provides the `tts` CLI
```

## 3. Flip the backend
```bash
# in ~/.claude/local-tts/config.env
LOCAL_TTS_BACKEND=xtts
LOCAL_TTS_SPEAKER_WAV="$HOME/.claude/local-tts/my-voice.wav"
```
Test: `~/.claude/local-tts/local-tts.sh --test` → now in your voice.

## Notes
- XTTS on CPU is ~1–3s/sentence (first call slower while the model loads). Fine for
  short lines; for long narration consider pre-caching wavs.
- To make Claude *speak every turn*, wire `local-tts.sh` into Claude Code hooks
  (Stop / UserPromptSubmit) — same idea as `golden-cloud/blocks/bella-tts`, but with
  this local engine instead of ElevenLabs.
