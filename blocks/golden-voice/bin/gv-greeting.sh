#!/bin/bash
# gv-greeting.sh — terminal-open serenade.
#
# Plays "Super skills activated" first, then a random shuffle of the OTHER clips
# in the greetings set. Reads ONLY from ~/.claude/local-tts/greetings/ — it never
# touches ~/.claude/local-tts/library/ (that set belongs to the Wordle app).
#
# Add more greeting voices:   gv greet <name> "the line to say"
#   e.g.  gv greet welcome-back "Welcome back, let's build something."
# They drop into greetings/ and get picked up here automatically.
#
# Non-blocking by design: config.fish backgrounds + disowns this whole script,
# so your prompt is usable the instant the terminal opens.
#
# Opt out:   touch ~/.claude/local-tts/no-greeting   (or export GV_NO_GREETING=1)
# Mute now:  stfu                                     (kills in-flight afplay)
# How many random clips after the intro:  export GV_GREETING_COUNT=3
set -uo pipefail

BASE="$HOME/.claude/local-tts"
GREET="$BASE/greetings"
INTRO="$GREET/super-skills-activated/super-skills-activated.mp3"
COUNT="${GV_GREETING_COUNT:-3}"

# Respect the opt-out switches.
[ -n "${GV_NO_GREETING:-}" ] && exit 0
[ -f "$BASE/no-greeting" ] && exit 0

command -v afplay >/dev/null 2>&1 || exit 0

play() { [ -s "$1" ] && afplay "$1" 2>/dev/null; }

# 1) The intro — always first.
play "$INTRO"

# 2) A random list of the rest of the greeting set: every mp3 under greetings/
#    except the intro, shuffled, capped at COUNT, played in order.
#    (bash 3.2 friendly — no mapfile.)
find "$GREET" -mindepth 2 -name '*.mp3' 2>/dev/null \
  | grep -v '/super-skills-activated/' \
  | sort -R \
  | head -n "$COUNT" \
  | while IFS= read -r c; do
      play "$c"
    done

# Clean exit even when the set is just the intro (empty shuffle + pipefail).
exit 0
