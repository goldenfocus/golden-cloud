#!/usr/bin/env bash
# new-block.sh — scaffold a new Golden Block.
# Usage: ./new-block.sh <block-name> [--public]

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: ./new-block.sh <block-name> [--public]"
  echo "example: ./new-block.sh voucher-issuer"
  exit 1
fi

NAME="$1"
PUBLIC=false
if [ "${2:-}" = "--public" ]; then
  PUBLIC=true
fi

if $PUBLIC; then
  ROOT="$HOME/golden-cloud-public"
else
  ROOT="$HOME/golden-cloud"
fi

DIR="$ROOT/blocks/$NAME"

if [ -e "$DIR" ]; then
  echo "block already exists: $DIR"
  exit 1
fi

mkdir -p "$DIR/src" "$DIR/tests" "$DIR/examples"

cat > "$DIR/README.md" <<EOF
# $NAME

> One-line description.

## What it does

...

## When to use

...

## When NOT to use

...

## Usage

\`\`\`
# example call
\`\`\`
EOF

cat > "$DIR/block.json" <<EOF
{
  "name": "$NAME",
  "version": "0.1.0",
  "summary": "TODO",
  "kind": "code",
  "language": "typescript",
  "inputs": [],
  "outputs": [],
  "dependencies": [],
  "tags": [],
  "public": $PUBLIC
}
EOF

touch "$DIR/src/.gitkeep" "$DIR/tests/.gitkeep" "$DIR/examples/.gitkeep"

echo "scaffolded: $DIR"
echo ""
echo "next: fill in README, block.json, drop code in src/, write a test in tests/"
