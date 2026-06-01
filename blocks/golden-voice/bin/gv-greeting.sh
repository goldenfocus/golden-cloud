#!/bin/bash
# gv-greeting.sh — terminal-open serenade.
#
# Plays ONE random clip from the greetings set on each terminal open. Every clip
# has an equal shot — "Super skills activated", "let's ship something worth
# shipping", or whatever else you add. Reads ONLY from
# ~/.claude/local-tts/greetings/ — never the Wordle library/.
#
# Add more greeting voices:   gv greet <name> "the line to say"
#   e.g.  gv greet ship "Let's ship something worth shipping."
# They join the random pool automatically.
#
# Non-blocking by design: config.fish backgrounds + disowns this whole script,
# so your prompt is usable the instant the terminal opens.
#
# Opt out:   touch ~/.claude/local-tts/no-greeting   (or export GV_NO_GREETING=1)
# Mute now:  stfu                                     (kills in-flight afplay)
# Play more than one (random, in order):  export GV_GREETING_COUNT=2
set -uo pipefail

BASE="$HOME/.claude/local-tts"
GREET="$BASE/greetings"
COUNT="${GV_GREETING_COUNT:-1}"

# Respect the opt-out switches.
[ -n "${GV_NO_GREETING:-}" ] && exit 0
[ -f "$BASE/no-greeting" ] && exit 0

command -v afplay >/dev/null 2>&1 || exit 0

# Pick COUNT random clip(s) from the whole greeting set and play them.
# (bash 3.2 friendly — no mapfile.)
find "$GREET" -mindepth 2 -name '*.mp3' 2>/dev/null \
  | sort -R \
  | head -n "$COUNT" \
  | while IFS= read -r c; do
      [ -s "$c" ] && afplay "$c" 2>/dev/null
    done

exit 0
