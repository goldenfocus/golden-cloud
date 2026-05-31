#!/bin/bash
# gv-depth.sh {full|medium|recap} — read text on stdin, emit spoken prose at the
# requested depth. full = code-stripped verbatim. medium/recap summarize via the
# configured LOCAL summarizer; if summarizer=none, fall back to full (never cloud).
set -uo pipefail
BASE="$HOME/.claude/local-tts"; PY="$BASE/xtts-venv/bin/python"
DEPTH="${1:-full}"
RAW=$(cat)
TEXT=$(printf '%s' "$RAW" | "$PY" "$BASE/bin/strip_prose.py")
case "$DEPTH" in
  full) printf '%s' "$TEXT" ;;
  medium|recap)
    SUM=$("$PY" "$BASE/bin/pa-settings.py" get summarizer)
    case "$SUM" in
      ollama:*)
        MODEL="${SUM#ollama:}"
        prompt="Summarize the following as a short spoken $DEPTH. Plain sentences, no markdown.\n\n$TEXT"
        printf '%b' "$prompt" | ollama run "$MODEL" 2>/dev/null ;;
      *) printf '%s' "$TEXT" ;;   # none / unknown -> safe local fallback
    esac ;;
  *) printf '%s' "$TEXT" ;;
esac
