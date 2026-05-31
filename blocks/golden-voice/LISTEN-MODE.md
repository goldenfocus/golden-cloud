# golden-voice — Daemon + Terminal Listen-Mode (Layer 0+1)

> Spec — 2026-05-31. Home of record for the golden-voice listen-mode build.
> Tool lives **outside p69** at `~/.claude/local-tts/` (local) and
> `goldenfocus/golden-cloud/blocks/golden-voice` (published). This spec syncs to
> golden-cloud when the slice publishes.

## Goal

Listen to what Claude says (and any selected text) in your own cloned voice,
from the terminal, with **pause / fast-forward / 2× / stop-anytime** — fast enough
to be pleasant because the model is resident, and **fully local + free** (no API
keys, no cloud, no bills). Foundation for the future Voice Studio UI and
collaborative voice library.

### Non-goals (explicitly out of this slice)
- push/blocker sound hooks (Layer 2) — the transport built here makes that a ~1-file add later.
- Web UI (Layer 3), app-integration SDK (4), collaborative voice sharing (5), multi-sensory (6).
- Abstractive summaries — only `full` (verbatim) ships now; `medium`/`recap` are a
  pluggable stub wired to **local Ollama** later (never cloud).

## Constraints (hard)
- **All local, all free.** XTTS (synth) · sox (fx) · mpv (playback) · Ollama (later). No network, no keys.
- **Instant trigger, no model round-trip** for auto-play and for transport controls
  (pause/ff/2×/stop). The only place a model is *ever* invoked is the manual
  `/play-audio medium|recap` path (later), via local Ollama.
- **Never commit biometrics** — voice samples, `my-voice.wav`, `xtts-venv/`, the
  generated `cache/` and `library/` stay local; `.gitignore` guards them.
- **Recording stays sox/CoreAudio** (the load-bearing gotcha) — unchanged here.

## Environment (verified 2026-05-31, Zang MBP)
- `xtts-venv/bin/tts-server` present (daemon backend); Python 3.11.15.
- `sox`, `ffmpeg`, `ffprobe`, `afplay`, `ffplay`, `pbpaste` present.
- `mpv` **missing** → one-time `brew install mpv` (live pause/ff/2×/stop via IPC socket).
- `ollama` present with `llama3.2:3b` + `qwen3:32b` (for later summaries; not used this slice).

## Architecture (Approach A: shell transport + thin `/play-audio` skill + mpv + daemon)

### Components (each isolated, one job)

| Unit | Job | Depends on |
|---|---|---|
| `tts-daemon` | Resident XTTS server via launchd. text+voice → wav. Model loaded once (~20s) then synth ~2s. | `xtts-venv/bin/tts-server` |
| `synth-client` | `local-tts.sh` evolves: daemon fast-path + cold-load fallback; apply fx; content-addressed cache (keep existing). | tts-daemon, sox |
| `voices` | Voice profiles at `voices/<name>/{samples/*.wav, voice.json}`. `voice.json` = fx preset + default speed/pitch. Default profile `me`. Folds in parked multi-sample averaging. | — |
| `player` | mpv against a per-host IPC socket. Controls namespaced under `gv` (`gv pause` / `gv ff` / `gv x2` / `gv stop`) to avoid shadowing shell builtins; optional short fish abbreviations addable later. Preserves pitch on speed change (scaletempo). | mpv |
| `queue` | File-based single-playback lock; serial drain across all tabs; spoken "Project X:" preamble when the project changes. | player |
| `capture` | Source text from (a) Stop-hook last assistant message or (b) clipboard (`pbpaste`). Strip fenced code, inline code, tool output, bare paths → prose. | — |
| `depth` | `full` = verbatim (this slice). `medium`/`recap` = pluggable interface, stubbed; later `ollama:llama3.2:3b`. | (later) ollama |
| `/play-audio` skill | Manual front door: `[full\|medium\|recap] [clip\|last]`, `auto on\|off`, `stop`, `voice <name>`, `set <key> <val>`. | capture, depth, synth-client, player |
| `settings` | `~/.claude/local-tts/play-audio.json` (see below). | — |
| `export` | Mint a clip to a reusable library (WAV master + Opus + MP3, −16 LUFS, manifest). | synth-client, ffmpeg |
| Stop hook | Auto-narrate finished turns per settings (instant, no model when depth=full). | capture, depth, queue |

### Data flow

**Auto (`settings.auto = true`):** turn finishes → Stop hook reads transcript's last
assistant message → `capture` strips code → `depth` (full = instant) → `queue`
enqueues `{project, text, voice}` → `player` synths via daemon, applies fx, plays via
mpv. If the enqueued project differs from what's playing and `announceProject` is on,
speak "Project X:" first.

**Manual:** `/play-audio [depth] [clip|last]` → `capture` (clipboard default, or last
answer) → `depth` → same queue/player path. `/play-audio stop` → flush queue + kill
mpv (silence at any point).

**Controls (terminal, while playing):** fish commands `gv pause` / `gv ff` / `gv x2`
/ `gv stop` write to the mpv IPC socket. Pure shell, instant, no model. (Optional
short abbreviations addable later if typing feels slow mid-listen.)

### The "instant, no AI thinking" guarantee
Two trigger surfaces never touch the model: the **Stop hook** (auto) and the bare
**fish control commands** (pause/ff/x2/stop). These run on every turn and every
control press. The **`/play-audio` skill** is only the deliberate manual front door,
and the only place a model token is ever spent (medium/recap, later, via local Ollama).
`auto` + `full` costs zero tokens and makes no network call.

## Settings — `~/.claude/local-tts/play-audio.json`
```jsonc
{
  "auto": false,                 // narrate every finished turn (default off → no multi-tab chaos)
  "defaultDepth": "full",        // full | medium | recap  (only full implemented this slice)
  "voice": "me",                 // voices/<name>
  "speed": 1.0,                  // base playback rate (mpv)
  "fxPreset": "clean",           // clean | warm | reverb | echo  (sox chains)
  "maxCharsBeforeCondense": 1200,// auto-full longer than this → medium (no-op until summarizer lands)
  "announceProject": true,       // "Project X:" preamble across tabs
  "summarizer": "none"           // later: "ollama:llama3.2:3b"
}
```
Editable by hand or `/play-audio set <key> <value>`.

## Effects (reverb / echo / pitch)
Named sox chains as `fxPreset` values, applied post-synth:
- `clean` — none
- `warm` — `bass +3 gain -1`
- `reverb` — `reverb 22 gain -1`
- `echo` — `echo 0.8 0.9 120 0.4`
Pitch is a per-voice knob in `voice.json` (`pitch` cents), applied via sox `pitch`.
Adding presets = one line; same chain the legacy `say` backend already proved.

## Audio export & library (forward-connects to Layers 3-5)
`/play-audio export <name>` (and `gv export`) mints to `~/.claude/local-tts/library/`:
- **WAV master** (lossless, source of truth).
- **Opus** (~24-32 kbps mono, primary web delivery) + **MP3** (universal fallback).
- **Loudness-normalized to −16 LUFS** (web/podcast standard) for consistent volume.
- **`library/manifest.json`** entries: `{id, text, voice, fx, speed, lufs, durationMs, files:{wav,opus,mp3}, createdISO}`.

The manifest is the exact data shape the future Voice Studio UI and collaborative
"Golden Speech" library will consume — built right once, now.

## File layout (all under `~/.claude/local-tts/`, all gitignored except scripts)
```
local-tts.sh            # synth-client (daemon fast-path + fallback + fx + cache)
tts-daemon.sh           # start/stop/status wrapper for the resident server
com.goldenvoice.tts-daemon.plist  # launchd unit (template; user installs)
play-audio.json         # settings (gitignored — user-specific)
voices/<name>/          # samples/*.wav + voice.json  (gitignored — biometric)
cache/                  # content-addressed synth output (gitignored)
library/                # exported clips + manifest.json (gitignored)
queue/                  # playback lock + queue files (gitignored)
~/.config/fish/functions/gv.fish   # CLI + namespaced controls (gv pause/ff/x2/stop)
~/.claude/hooks/play-audio-stop.sh                   # Stop hook (auto narrate)
~/.claude/commands/play-audio.md                     # the /play-audio skill
```

## Testing
- **Unit:** code-stripper (fenced + inline + tool noise + paths), settings parse/merge,
  cache-key invalidation on re-record, queue ordering + project-change announce.
- **Integration:** daemon synth smoke (text→wav < ~3s warm); export produces wav+opus+mp3
  all at −16 LUFS ±1; cold-fallback path works when daemon down.
- **Manual:** live pause/ff/2×/stop via mpv socket; two-tab queue serializes + announces.

## Open items resolved
- Summaries: **full-only now**, pluggable later via local Ollama (installed). No cloud.
- Player: **mpv** (one-time brew install) for live 2× + IPC control.
- Default `auto: false` to avoid multi-tab cacophony.
- Library at `~/.claude/local-tts/library/`, local now, syncable later.

## Divergence cleanup folded in (from prior handover)
- Resolve the half-removed "named clips": orphan `clips/ship.wav` + root `*.wav`
  (`hype-1m-stars`, `hypnosis`) get migrated into the new `library/` model (or removed).
- Exercise multi-sample averaging for real (currently coded, `samples/` never created) —
  verify the coqui `tts` CLI actually averages multiple `--speaker_wav` vs taking the last.

**RESOLVED 2026-05-31:**
- Multi-sample averaging VERIFIED working — the resident daemon accepts a list of
  `speaker_wavs` and synth succeeds with >1 sample (covered green in `run-tests.sh`).
- Orphan clips (`clips/ship.wav`, `hype-1m-stars.wav`, `hypnosis.wav`) migrated into
  `library/` (each → `library/<name>/<name>.wav`; originals left in place).
- `gv say` now routes through the IPC player (`gv-play.sh`) so live controls
  (`gv pause` / `gv ff` / `gv x2` / `gv stop`) apply to it.
