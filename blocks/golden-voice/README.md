# golden-voice — clone your voice, speak anything, pay nothing

Record 30 seconds of yourself talking. golden-voice clones your voice **locally**
with [XTTS-v2](https://github.com/coqui-ai/TTS) and gives you a one-command TTS that
sounds like you. No cloud, no API keys, no monthly bill.

It ships with two interchangeable backends behind one pipeline:

| Backend | What | Install |
|---------|------|---------|
| `say` *(default)* | macOS built-in voice | nothing — works instantly |
| `xtts` *(later)* | **your** voice, cloned locally on CPU | one `brew install`, one `pip install` |

Flip between them with a single variable in `config.env`. Nothing else changes.

## Why this exists

This is the free, self-owned cousin of [`bella-tts`](../bella-tts) (which streams
through ElevenLabs). bella-tts is great, but a paid API key burns quota fast with
multiple dev sessions running, and the cost doesn't scale. golden-voice runs the
whole thing on your laptop:

- **Free forever** — no per-character billing, no quota
- **No API keys** — nothing to provision, rotate, or leak
- **Private** — your voice sample and the synthesis never leave your machine
- **Yours** — XTTS-v2 is open source (Coqui); you own the pipeline end to end

## Requirements

- macOS (Apple Silicon or Intel)
- Homebrew
- Python 3.11 — the installer adds it via `brew` (system python is 3.9; XTTS needs 3.11)
- `sox` — for clean recording + optional effects (installer adds it)
- ~2GB disk for the XTTS-v2 model (downloaded once, on first `xtts` run)
- A 15–30 second recording of your voice (you make it with `record-voice.sh`)

## Install

```bash
git clone https://github.com/goldenfocus/golden-cloud.git
cd golden-cloud/blocks/golden-voice
bash install.sh
```

The installer is idempotent. It:
1. Copies `local-tts.sh` + `record-voice.sh` to `~/.claude/local-tts/`
2. Seeds `~/.claude/local-tts/config.env` from the template (defaults to `say`)
3. `brew install`s `python@3.11` + `sox` if missing
4. Creates a Python 3.11 venv and `pip install`s `coqui-tts` (the XTTS engine)
5. Smoke-tests the `say` backend

It does **not** record your voice for you — that's your private biometric, so
golden-voice never ships a sample. You capture your own in the next step.

## Usage

```bash
# speak an argument
~/.claude/local-tts/local-tts.sh "hello from my own machine"

# speak piped text
echo "narration goes here" | ~/.claude/local-tts/local-tts.sh

# built-in demo line
~/.claude/local-tts/local-tts.sh --test
```

### Switching to your own voice (the whole point)

```bash
# 1. record 15-30s of yourself talking naturally
~/.claude/local-tts/record-voice.sh        # → ~/.claude/local-tts/my-voice.wav

# 2. flip the backend in ~/.claude/local-tts/config.env
LOCAL_TTS_BACKEND=xtts

# 3. speak — now in your voice (first run downloads the ~1.8GB model once)
~/.claude/local-tts/local-tts.sh --test
```

To go back to the instant macOS voice, set `LOCAL_TTS_BACKEND=say` (or unset it).

## ⚠️ Recording gotcha — use sox/CoreAudio, not ffmpeg/avfoundation

This is the load-bearing lesson baked into `record-voice.sh`, and the reason it
exists instead of a one-line ffmpeg command:

> On Apple hardware, capturing the mic through `ffmpeg -f avfoundation` produced a
> persistent buzzy / "electrical" hum on the recording. Trying to clean it up with
> resampling or `loudnorm` made it **worse**, not better.
>
> The clean fix was native **sox → CoreAudio** capture at 48k/24-bit, with only a
> gentle `highpass 70 gain -n -1.5` (rumble cut + peak-normalize) — **no**
> resampling, **no** loudnorm.

`record-voice.sh` does exactly that by default. ffmpeg+avfoundation remains only as a
clearly-labelled fallback for machines without sox. If your clone sounds buzzy or
robotic, re-record with sox (the default) before blaming the model — a clean sample
is 90% of clone quality.

## Configuration

Edit `~/.claude/local-tts/config.env` (see `config.env.example` for the full set):

| Variable | Meaning | Default |
|----------|---------|---------|
| `LOCAL_TTS_BACKEND` | `say` or `xtts` | `say` |
| `LOCAL_TTS_VOICE` | a macOS `say` voice name | best installed, auto-picked |
| `LOCAL_TTS_RATE` | words per minute | `180` |
| `LOCAL_TTS_EFFECTS` | sox effect chain (e.g. `reverb 22 bass +3`) | none |
| `LOCAL_TTS_SPEAKER_WAV` | path to your clone sample (`xtts` only) | `~/.claude/local-tts/my-voice.wav` |

## Files

| File | Purpose |
|------|---------|
| `local-tts.sh` | The pluggable TTS wrapper (`say` + `xtts` backends) |
| `record-voice.sh` | Capture a clean voice sample via sox/CoreAudio |
| `config.env.example` | Sanitized config template (installer seeds `config.env` from it) |
| `install.sh` | Idempotent installer (scripts + Python 3.11 venv + coqui-tts) |
| `XTTS-LATER.md` | Manual XTTS setup + troubleshooting reference |

## What never lives in this repo

`*.wav` voice samples (biometric) and the multi-GB `xtts-venv/` are git-ignored. Your
voice stays on your machine. This block is the tooling only — bring your own voice.

## Wiring into Claude Code

To make Claude speak every turn, wire `local-tts.sh` into Claude Code hooks
(`Stop` / `UserPromptSubmit`) — same idea as [`bella-tts`](../bella-tts), but with
this local engine instead of ElevenLabs.

---

MIT licensed. Part of [Golden Blocks](https://github.com/goldenfocus/golden-blocks).
