#!/bin/bash
# gv-ctl.sh {pause|ff|x2|stop} — drive the current mpv via its IPC socket.
set -uo pipefail
BASE="$HOME/.claude/local-tts"; SOCK="$BASE/queue/mpv.sock"; STATE="$BASE/queue/speed.state"
send() { printf '%s\n' "$1" | nc -U "$SOCK" >/dev/null 2>&1; }
case "${1:-}" in
  pause) send '{"command":["cycle","pause"]}' ;;
  ff)    send '{"command":["seek",10]}' ;;
  x2)
    cur=$(cat "$STATE" 2>/dev/null || echo 1.0)
    if [ "$cur" = "2.0" ]; then nw=1.0; else nw=2.0; fi
    send "{\"command\":[\"set_property\",\"speed\",$nw]}"; echo "$nw" > "$STATE" ;;
  stop)
    rm -f "$BASE/queue/pending"/*.json 2>/dev/null   # flush the queue (silence now)
    send '{"command":["quit"]}'
    rmdir "$BASE/queue/lock" 2>/dev/null || true ;;
  *) echo "usage: gv-ctl.sh {pause|ff|x2|stop}"; exit 2 ;;
esac
