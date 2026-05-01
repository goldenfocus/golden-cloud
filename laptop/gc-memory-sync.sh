#!/usr/bin/env bash
# gc-memory-sync.sh — wire ~/golden-cloud/memory/ into every Claude Code per-project memory dir.
#
# For each ~/.claude/projects/*/memory/ dir:
#   1. Ensure `shared/` is a symlink to ~/golden-cloud/memory/
#   2. Regenerate the `<!-- shared:start -->...<!-- shared:end -->` section of MEMORY.md
#      using the contents of ~/golden-cloud/memory/MEMORY.md, with .md links rewritten
#      to point through the `shared/` symlink.
#
# Safe to re-run. Idempotent. Doesn't touch local memory files or the `## Local` section.

set -euo pipefail

GC_MEM="$HOME/golden-cloud/memory"
PROJECTS_DIR="$HOME/.claude/projects"

[ -d "$GC_MEM" ] || { echo "ERR: $GC_MEM doesn't exist — create it first" >&2; exit 1; }
[ -f "$GC_MEM/MEMORY.md" ] || { echo "ERR: $GC_MEM/MEMORY.md is missing" >&2; exit 1; }
if [ ! -d "$PROJECTS_DIR" ]; then
  echo "info: $PROJECTS_DIR doesn't exist yet — Claude Code hasn't run on this laptop. Re-run this script after first Claude Code session." >&2
  exit 0
fi

count=0
skipped=0

for proj_mem in "$PROJECTS_DIR"/*/memory; do
  [ -d "$proj_mem" ] || continue

  shared="$proj_mem/shared"
  if [ -L "$shared" ]; then
    ln -snf "$GC_MEM" "$shared"
  elif [ -e "$shared" ]; then
    echo "skip (shared/ exists and is not a symlink): $proj_mem" >&2
    skipped=$((skipped+1))
    continue
  else
    ln -s "$GC_MEM" "$shared"
  fi

  mem_md="$proj_mem/MEMORY.md"
  [ -f "$mem_md" ] || : > "$mem_md"

  # Capture everything up to the auto-synced marker (or the whole file if no marker yet)
  local_section=$(awk '
    /^<!-- shared:start -->/ { exit }
    { print }
  ' "$mem_md")

  # Body of the canonical golden-cloud index, minus its H1 title, with .md links
  # rewritten to point through the shared/ symlink in the project dir.
  shared_body=$(awk 'NR>1' "$GC_MEM/MEMORY.md" | sed -E 's|\]\(([^)]+\.md)\)|](shared/\1)|g')

  {
    if [ -n "$local_section" ]; then
      printf '%s\n' "$local_section"
      # ensure exactly one blank line between local and shared sections
      printf '\n'
    fi
    echo "<!-- shared:start -->"
    echo "<!-- auto-synced from ~/golden-cloud/memory/MEMORY.md by gc-memory-sync.sh — do not edit by hand -->"
    echo ""
    printf '%s\n' "$shared_body"
    echo "<!-- shared:end -->"
  } > "$mem_md.new"
  mv "$mem_md.new" "$mem_md"

  count=$((count+1))
  echo "synced: $proj_mem"
done

echo ""
echo "OK: linked $count project memory dirs to $GC_MEM (skipped: $skipped)"
