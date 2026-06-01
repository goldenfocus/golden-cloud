#!/usr/bin/env bash
# Claude Code docs change-watcher.
# Fetches the official docs index, diffs vs cached snapshot, prints new/changed entries.
# Run weekly (cron or `/loop` skill). Does NOT auto-update the cache — you must mv after review.

set -euo pipefail

URL="https://code.claude.com/docs/llms.txt"
CACHE_DIR="$HOME/golden-cloud/claude-code"
CACHED="$CACHE_DIR/llms.txt.cache"
TMP="$CACHE_DIR/llms.txt.new"

mkdir -p "$CACHE_DIR"

if ! curl -fsSL "$URL" -o "$TMP"; then
  echo "ERROR: failed to fetch $URL" >&2
  rm -f "$TMP"
  exit 1
fi

if [[ ! -f "$CACHED" ]]; then
  mv "$TMP" "$CACHED"
  echo "First run — cached current docs index at $CACHED"
  echo "Next run will print any diffs."
  exit 0
fi

if diff -q "$CACHED" "$TMP" >/dev/null; then
  rm "$TMP"
  echo "No changes since last check ($(date -r "$CACHED" '+%Y-%m-%d %H:%M'))."
  exit 0
fi

echo "================================================================"
echo "Claude Code docs index CHANGED since $(date -r "$CACHED" '+%Y-%m-%d %H:%M')"
echo "Source: $URL"
echo "----------------------------------------------------------------"
echo "ADDED / CHANGED LINES:"
diff "$CACHED" "$TMP" | sed -n 's/^> //p' | head -200
echo "----------------------------------------------------------------"
echo "REMOVED LINES:"
diff "$CACHED" "$TMP" | sed -n 's/^< //p' | head -50
echo "----------------------------------------------------------------"
echo "Full diff: diff '$CACHED' '$TMP'"
echo "Accept changes: mv '$TMP' '$CACHED'"
echo "================================================================"
# Deliberately NOT auto-updating the cache. If you re-run before accepting,
# you'll see the same diff again — that's intentional. Drift by default
# would silently lose track of changes you skimmed without internalizing.
