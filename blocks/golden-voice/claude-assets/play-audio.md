---
name: play-audio
description: Speak text in your cloned voice from the terminal. Use when the user says "play audio", "read this", "listen", "/play-audio", or wants spoken playback of the clipboard or the last answer. Modes: full | medium | recap. Also toggles auto-narration and stops playback.
---

# /play-audio

Speak text aloud in the user's local cloned voice (golden-voice). 100% local, free.

This is a THIN wrapper. Do NOT reason about the content. Run the matching shell command immediately and report one line.

## Routing

- `/play-audio` or `/play-audio full` → read the clipboard, full:
  `bash ~/.claude/local-tts/bin/gv-pipe.sh clip full "$(basename "$PWD")"`
- `/play-audio last` → read the user's last answer (this session transcript), full:
  `GV_TRANSCRIPT="$CLAUDE_TRANSCRIPT_PATH" bash ~/.claude/local-tts/bin/gv-pipe.sh last full "$(basename "$PWD")"`
- `/play-audio recap` (or `medium`) → summarize then speak (local Ollama if configured, else full):
  `GV_TRANSCRIPT="$CLAUDE_TRANSCRIPT_PATH" bash ~/.claude/local-tts/bin/gv-pipe.sh last recap "$(basename "$PWD")"`
- `/play-audio stop` → silence now: `bash ~/.claude/local-tts/bin/gv-ctl.sh stop`
- `/play-audio auto on|off` → `~/.claude/local-tts/xtts-venv/bin/python ~/.claude/local-tts/bin/pa-settings.py set auto <true|false>`
- `/play-audio voice <name>` → `~/.claude/local-tts/xtts-venv/bin/python ~/.claude/local-tts/bin/pa-settings.py set voice <name>`

After running, reply with just: `🔊 <what you did>` (e.g. `🔊 reading clipboard (full)`).
