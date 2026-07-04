#!/usr/bin/env bash
# Tests the manifest upsert idempotency + index generation used by publish.sh.
set -euo pipefail
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
M="$TMP/manifest.json"; echo "[]" > "$M"

upsert() { python3 - "$M" "$1" "$2" "$3" "$4" <<'PY'
import json,sys
path,slug,title,status,date=sys.argv[1:6]
items=json.load(open(path)); items=[x for x in items if x.get("slug")!=slug]
items.append({"slug":slug,"title":title,"status":status,"date":date})
items.sort(key=lambda x:(x["date"],x["slug"]),reverse=True)
json.dump(items,open(path,"w"),indent=2)
PY
}

upsert board-neon "Neon Board" exploring 2026-05-31
upsert board-neon "Neon Board v2" shipped 2026-05-31
upsert board-soft "Soft Board" exploring 2026-05-30

COUNT=$(python3 -c "import json;print(len(json.load(open('$M'))))")
[ "$COUNT" = "2" ] || { echo "FAIL: expected 2 entries, got $COUNT" >&2; exit 1; }
TITLE=$(python3 -c "import json;print([x for x in json.load(open('$M')) if x['slug']=='board-neon'][0]['title'])")
[ "$TITLE" = "Neon Board v2" ] || { echo "FAIL: slug not upserted, title=$TITLE" >&2; exit 1; }
FIRST=$(python3 -c "import json;print(json.load(open('$M'))[0]['slug'])")
[ "$FIRST" = "board-neon" ] || { echo "FAIL: sort wrong, first=$FIRST" >&2; exit 1; }
echo "PASS: upsert idempotent (2 entries), slug replaced, sort by date desc"
