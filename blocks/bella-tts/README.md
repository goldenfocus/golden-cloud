# Bella TTS — Voice narration for Claude Code

Claude reads its responses aloud through ElevenLabs' streaming TTS. Audio starts ~300ms after the response lands.

## What it does

- **Auto recap** — when Claude finishes a turn, it plays a chime and speaks a 1-2 sentence summary
- **Full replay** — hotkey to hear the entire last response read aloud
- **Read selection** — hotkey to read any selected text in any app
- **Mid-turn narration** — scripts can narrate progress while Claude is still working
- **Tab indicator** — pulsing speaker icon in the terminal tab title while playing

## Requirements

- macOS (uses Keychain, afplay, Ghostty/iTerm tab titles)
- [ElevenLabs](https://elevenlabs.io) API key (free tier works, ~10k chars/month)
- `brew install jq ffmpeg` (ffplay for streaming audio)
- Claude Code CLI

## Install

```bash
# Clone golden-cloud-public (if you haven't)
git clone https://github.com/goldenfocus/golden-cloud-public.git ~/golden-cloud-public

# Run the installer
bash ~/golden-cloud-public/blocks/bella-tts/install.sh
```

The installer:
1. Copies hook scripts to `~/.claude/hooks/`
2. Stores your ElevenLabs key in macOS Keychain
3. Finds or sets the Bella voice ID
4. Wires the Claude Code hooks in `~/.claude/settings.json`
5. Plays a test clip

## Optional hotkeys (skhd)

```bash
# ~/.skhdrc
alt - b : bash ~/.claude/hooks/bella-speak.sh          # toggle full replay
alt + shift - b : bash ~/.claude/hooks/bella-speak-selection.sh  # read selection
```

## Customization

Edit `~/.claude/bella-tts/config.json`:

```json
{
  "voice_id": "EXAVITQu4vr4xnSDxMaA",
  "model_id": "eleven_turbo_v2_5",
  "char_cap": 5000
}
```

- `voice_id` — any ElevenLabs voice ID (default: Bella)
- `model_id` — `eleven_turbo_v2_5` for speed, `eleven_multilingual_v2` for quality
- `char_cap` — max characters to speak (saves API credits)

## Scripts

| Script | Purpose |
|--------|---------|
| `bella-setup.sh` | One-time setup (API key + voice detection) |
| `bella-speak.sh` | Toggle full playback of last response |
| `bella-speak-selection.sh` | Read selected text from any app |
| `bella-narrate.sh` | Mid-turn narration (`bella-narrate.sh "checking now..."`) |
| `bella-status.sh` | Show current playback state |
| `bella-reset.sh` | Kill playback + clear stuck tab title |
| `bella-pointer.sh` | Hook: tracks active transcript (UserPromptSubmit) |
| `bella-complete.sh` | Hook: chime + recap on turn end (Stop) |
| `bella-player.py` | Core TTS engine (ElevenLabs streaming → ffplay) |

## How it works

1. `bella-pointer.sh` fires on every user prompt, saving the active JSONL transcript path
2. When Claude stops, `bella-complete.sh` plays a system chime and launches `bella-player.py` in recap mode
3. The player extracts the latest assistant message from the JSONL transcript, strips markdown/code/tables, and streams the first ~220 chars through ElevenLabs → ffplay
4. Full replay reads the entire response (up to `char_cap`)
