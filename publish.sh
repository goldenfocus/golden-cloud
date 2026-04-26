#!/usr/bin/env bash
# publish.sh — move a file from Golden Cloud (private) to Golden Cloud Public.
# Usage: ./publish.sh notes/some-idea.md

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: ./publish.sh <relative-path>"
  echo "example: ./publish.sh notes/my-thoughts.md"
  exit 1
fi

REL="$1"
PRIVATE_DIR="$(cd "$(dirname "$0")" && pwd)"
PUBLIC_DIR="$HOME/golden-cloud-public"

SRC="$PRIVATE_DIR/$REL"
DST="$PUBLIC_DIR/$REL"

if [ ! -f "$SRC" ]; then
  echo "file not found: $SRC"
  exit 1
fi

if [ ! -d "$PUBLIC_DIR" ]; then
  echo "public repo not cloned at $PUBLIC_DIR"
  echo "run: gh repo clone goldenfocus/golden-cloud-public $PUBLIC_DIR"
  exit 1
fi

mkdir -p "$(dirname "$DST")"
mv "$SRC" "$DST"

# Commit in public
cd "$PUBLIC_DIR"
git add "$REL"
git commit -m "publish: $REL"
git push

# Commit the removal in private
cd "$PRIVATE_DIR"
git add "$REL"
git commit -m "publish: moved $REL to public"
git push

echo ""
echo "published: https://github.com/goldenfocus/golden-cloud-public/blob/main/$REL"
echo "raw URL:   https://raw.githubusercontent.com/goldenfocus/golden-cloud-public/main/$REL"
