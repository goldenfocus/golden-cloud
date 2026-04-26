#!/usr/bin/env bash
# gc-memory-autocommit.sh — invoked by Claude Code Stop hook.
#
# Job:
#   1. Run gc-memory-sync.sh (regenerates each project's MEMORY.md `## Shared`
#      section from ~/golden-cloud/memory/MEMORY.md).
#   2. Commit + push any changes under ~/golden-cloud/memory/ (and laptop/).
#
# Contract:
#   - ALWAYS exits 0. Never blocks Claude from completing its turn.
#   - Reads hook JSON from stdin, extracts session_id for commit attribution.
#   - Outputs `{"systemMessage": "..."}` to stdout only when something happened.
#   - Stays silent on no-op turns (most turns don't touch shared memory).

set +e
set -u

hook_input=$(cat 2>/dev/null || echo '{}')
session_id=$(printf '%s' "$hook_input" | jq -r '.session_id // ""' 2>/dev/null | head -c 8)

# Step 1: regenerate per-project MEMORY.md ## Shared sections (idempotent)
"$HOME/golden-cloud/laptop/gc-memory-sync.sh" > /dev/null 2>&1

# Step 2: commit + push any changes in memory/ or laptop/
cd "$HOME/golden-cloud" 2>/dev/null || exit 0

changes=$(git status --porcelain memory/ laptop/ 2>/dev/null)
if [ -z "$changes" ]; then
  exit 0
fi

git add memory/ laptop/ 2>/dev/null

if git diff --cached --quiet 2>/dev/null; then
  exit 0
fi

commit_msg="gc-memory: auto-sync"
[ -n "$session_id" ] && commit_msg="$commit_msg (session $session_id)"

if ! git commit -m "$commit_msg" --quiet 2>/dev/null; then
  exit 0
fi

# Pull --rebase first to avoid push rejection if yan pushed in parallel
git pull --rebase --quiet origin main 2>/dev/null || true

if git push --quiet 2>/dev/null; then
  printf '{"systemMessage":"💾 gc-memory: auto-synced + pushed — %s"}\n' "$commit_msg"
else
  printf '{"systemMessage":"⚠️ gc-memory: committed locally; push failed (network/auth?)"}\n'
fi

exit 0
