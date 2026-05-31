#!/bin/bash
# tts-daemon.sh — start|stop|status|restart the resident XTTS daemon.
set -uo pipefail
BASE="$HOME/.claude/local-tts"
PY="$BASE/xtts-venv/bin/python"
PIDF="$BASE/queue/tts-daemon.pid"
LOG="$BASE/queue/tts-daemon.log"
URL="http://127.0.0.1:5111/health"
mkdir -p "$BASE/queue"

is_up() { curl -sf -m 2 "$URL" >/dev/null 2>&1; }

case "${1:-status}" in
  start)
    if is_up; then echo "already up"; exit 0; fi
    nohup "$PY" "$BASE/bin/tts_daemon.py" >"$LOG" 2>&1 &
    echo $! > "$PIDF"
    echo "starting (pid $(cat "$PIDF")) — model load ~20s; tail $LOG"
    ;;
  stop)
    [ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null && rm -f "$PIDF" && echo "stopped" || echo "not running"
    ;;
  restart) "$0" stop; sleep 1; "$0" start ;;
  status) is_up && echo "up" || echo "down" ;;
  *) echo "usage: tts-daemon.sh {start|stop|status|restart}"; exit 2 ;;
esac
