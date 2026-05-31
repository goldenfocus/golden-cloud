# golden-voice — clone your voice, hear your terminal speak it, pay nothing

Record 30 seconds of yourself talking. golden-voice clones your voice **locally**
with [XTTS-v2](https://github.com/coqui-ai/TTS), then speaks anything you want — in
your own voice, from the terminal, with live **pause / fast-forward / 2× / stop**.
No cloud, no API keys, no monthly bill.

- **Free forever** — no per-character billing, no quota
- **No API keys** — nothing to provision, rotate, or leak
- **Private** — your voice sample and the synthesis never leave your machine
- **Yours** — XTTS-v2 is open source (Coqui); you own the pipeline end to end
- **Fast** — a resident daemon keeps the model loaded, so synth is ~2s, not ~20s

It also plugs straight into Claude Code: a `/play-audio` skill reads your clipboard
or last answer aloud, and an opt-in Stop hook can auto-narrate every finished turn.

## Requirements

- macOS (Apple Silicon or Intel)
- Homebrew
- Python 3.11 — the installer adds it via `brew` (system python is 3.9; XTTS needs 3.11)
- `sox` — clean CoreAudio recording + the fx chains
- `mpv` — playback engine with live IPC controls (pause / ff / 2× / stop)
- `ffmpeg` — loudness normalization + Opus/MP3 encoding for exports
- ~2GB disk for the XTTS-v2 model (downloaded once, on first synth)
- A 15–30 second recording of your voice (you make it with `gv record`)
- *Optional:* [Ollama](https://ollama.com) running locally for `medium`/`recap`
  summaries (local-only, never cloud; `full` verbatim works without it)

## Install

```bash
git clone https://github.com/goldenfocus/golden-cloud.git
cd golden-cloud/blocks/golden-voice
bash install.sh
```

The installer is idempotent. It:
1. `brew install`s `python@3.11`, `sox`, `mpv`, `ffmpeg` if missing
2. Copies `local-tts.sh`, `record-voice.sh`, `tts-daemon.sh`, the launchd plist,
   and the whole `bin/` into `~/.claude/local-tts/`
3. Installs the `gv` fish command to `~/.config/fish/functions/`
4. Creates a Python 3.11 venv and `pip install`s the XTTS engine
5. Smoke-tests the macOS `say` backend

It does **not** record your voice — that's your private biometric, so golden-voice
never ships a sample. You capture your own (next step). It also does **not** touch
your Claude Code settings; the skill + hook are documented manual steps below.

## Quick start

```bash
# 1. record 15-30s of yourself talking naturally (more clips = better clone)
gv record                     # → voices/me/samples/… (stays on YOUR machine)

# 2. start the resident daemon (model loads once, ~20s; then synth is ~2s)
bash ~/.claude/local-tts/tts-daemon.sh start

# 3. speak in your voice
gv say "hello from my own machine"
```

The first synth downloads the ~1.8GB XTTS-v2 model once. Identical phrases are
content-cached, so repeats are instant.

## The resident daemon

XTTS takes ~20s to load. The daemon loads it **once** and keeps it resident, so
every synth after is ~2s. `local-tts.sh` automatically prefers the daemon and
falls back to a cold per-call invocation if it isn't running.

```bash
bash ~/.claude/local-tts/tts-daemon.sh start     # start (model load ~20s)
bash ~/.claude/local-tts/tts-daemon.sh status    # up | down
bash ~/.claude/local-tts/tts-daemon.sh restart
bash ~/.claude/local-tts/tts-daemon.sh stop
```

It listens on `127.0.0.1:5111` (local only, no network exposure).

### Optional: autostart at login (launchd)

```bash
sed "s#__HOME__#$HOME#g" ~/.claude/local-tts/com.goldenvoice.tts-daemon.plist \
  > ~/Library/LaunchAgents/com.goldenvoice.tts-daemon.plist
launchctl load ~/Library/LaunchAgents/com.goldenvoice.tts-daemon.plist
```

## The `gv` command

The installer drops a `gv` fish helper. Run `gv` with no args for the cheat sheet.

```fish
gv say "ship it"                       # speak now (cached → repeats instant)
gv play clip                           # read the clipboard
gv play last                           # read your last answer (in Claude Code)
gv play clip full|medium|recap         # choose depth (medium/recap need Ollama)
gv record [label]                      # add a voice sample (more = better clone)
gv samples                             # list your samples + durations
gv export <name> "text"                # mint a library clip (wav + opus + mp3)
gv auto on|off                         # toggle auto-narration (Stop hook)
gv set <key> <val>                     # edit a setting (see Settings)

# live playback controls (while something is speaking):
gv pause                               # pause / resume
gv ff                                  # jump forward 10s
gv x2                                  # toggle 2× speed (pitch preserved)
gv stop                                # silence now + flush the queue
```

Controls are pure shell over an mpv IPC socket — instant, no model round-trip.

## Claude Code integration (`/play-audio` skill + auto-narration hook)

These two assets live in `claude-assets/` and are **not** installed automatically
(editing your Claude Code config is too invasive for an installer). Install them by hand:

1. **The `/play-audio` skill** — reads clipboard / last answer aloud on demand:
   ```bash
   mkdir -p ~/.claude/commands
   cp claude-assets/play-audio.md ~/.claude/commands/
   ```
   Then in Claude Code: `/play-audio`, `/play-audio last`, `/play-audio recap`,
   `/play-audio stop`, `/play-audio auto on|off`.

2. **The auto-narration Stop hook** — speaks every finished turn (opt-in, **off by
   default**):
   ```bash
   mkdir -p ~/.claude/hooks
   cp claude-assets/play-audio-stop.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/play-audio-stop.sh
   ```
   Register it as a `Stop` hook in `~/.claude/settings.json`:
   ```jsonc
   {
     "hooks": {
       "Stop": [
         { "hooks": [ { "type": "command", "command": "~/.claude/hooks/play-audio-stop.sh" } ] }
       ]
     }
   }
   ```
   The hook does nothing until you opt in with `gv auto on` (default `auto: false`,
   to avoid multi-tab cacophony). It never blocks the turn and, at `full` depth,
   spends zero tokens and makes no network call.

## Settings — `~/.claude/local-tts/play-audio.json`

Edit by hand or with `gv set <key> <value>`:

| Key | Meaning | Default |
|-----|---------|---------|
| `auto` | narrate every finished turn (Stop hook) | `false` |
| `defaultDepth` | `full` \| `medium` \| `recap` | `full` |
| `voice` | active profile under `voices/<name>` | `me` |
| `speed` | base playback rate (mpv) | `1.0` |
| `fxPreset` | `clean` \| `warm` \| `reverb` \| `echo` | `clean` |
| `maxCharsBeforeCondense` | auto-condense turns longer than this | `1200` |
| `announceProject` | speak "Project X." when the project changes | `true` |
| `summarizer` | local summarizer, e.g. `ollama:llama3.2:3b` | `none` |

Only `full` (verbatim) depth ships now. `medium`/`recap` are a pluggable interface:
with `summarizer` set to a local Ollama model they summarize locally; otherwise they
safely fall back to `full`. **Never cloud.**

## Voice profiles & multi-sample averaging

Voices live at `voices/<name>/`:

```
voices/me/
  samples/*.wav     # your recordings — more clips average to a better clone
  voice.json        # optional per-voice knobs, e.g. { "pitch": 0 }
```

`gv record` appends a new sample to the active profile. The synth path passes **all**
samples to XTTS, which averages them — so the more (clean) clips you record, the
closer the clone. `voice.json.pitch` (in cents) is applied via a sox `pitch` shift.

## Effects (fx presets)

Named sox chains applied post-synth, selected via `fxPreset`:

- `clean` — none
- `warm` — `bass +3 gain -1`
- `reverb` — `reverb 22 gain -1`
- `echo` — `echo 0.8 0.9 120 0.4`

Adding a preset is one line in `local-tts.sh`.

## Export & the library

`gv export <name> "text"` mints a reusable, web-ready clip to
`~/.claude/local-tts/library/<name>/`:

- **WAV master** (lossless source of truth)
- **Opus** (~28 kbps mono — primary web delivery) + **MP3** (universal fallback)
- **Loudness-normalized to −16 LUFS** (web/podcast standard) for consistent volume
- An entry in **`library/manifest.json`**:
  `{ id, text, voice, fx, durationMs, lufs, files: { wav, opus, mp3 }, createdISO }`

The manifest is the exact data shape a future Voice Studio UI / shared voice library
will consume — built right once, now.

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

## Privacy — what never leaves your machine, what never enters this repo

Your **voice sample and every synthesis stay 100% local**. Synthesis runs on your
CPU; the daemon binds to `127.0.0.1` only. Nothing is uploaded, ever.

All biometrics and generated audio are git-ignored and **never** committed:
`*.wav`, `*.opus`, `*.mp3`, `*.aiff`, `voices/`, `cache/`, `library/`, `queue/`,
`xtts-venv/`, `play-audio.json`, and your real `config.env`. This block is the
**tooling only** — bring your own voice.

## Files

| File | Purpose |
|------|---------|
| `local-tts.sh` | Synth-client: daemon fast-path + cold fallback + fx + content cache |
| `tts-daemon.sh` | start / stop / status / restart for the resident XTTS server |
| `com.goldenvoice.tts-daemon.plist` | launchd template for daemon autostart |
| `record-voice.sh` | Capture a clean voice sample via sox/CoreAudio |
| `gv.fish` | The `gv` CLI + live playback controls |
| `bin/tts_daemon.py` | Resident XTTS-v2 HTTP synth server (model loaded once) |
| `bin/synth & queue scripts` | `gv-capture` / `gv-depth` / `gv-enqueue` / `gv-drain` / `gv-play` / `gv-ctl` / `gv-pipe` / `gv-export` |
| `bin/pa-settings.py` | Read/write `play-audio.json` settings |
| `bin/strip_prose.py` | Reduce markdown/tool output to clean spoken prose |
| `claude-assets/play-audio.md` | The `/play-audio` Claude Code skill (manual install) |
| `claude-assets/play-audio-stop.sh` | Auto-narration Stop hook (manual install, opt-in) |
| `config.env.example` | Sanitized config template |
| `install.sh` | Idempotent installer |
| `LISTEN-MODE.md` | Architecture + spec for the listen-mode build |
| `XTTS-LATER.md` | Manual XTTS setup + troubleshooting reference |

---

MIT licensed. Part of [Golden Blocks](https://github.com/goldenfocus/golden-blocks).
