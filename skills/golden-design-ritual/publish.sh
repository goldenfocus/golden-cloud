#!/usr/bin/env bash
# Publish a single design prototype to a project's R2-backed design gallery.
#
# Usage: publish.sh <html-file> <slug> "<title>" [status] [config-path]
#   config-path defaults to ./.claude/design-ritual.json
#
# Reads {site, r2_bucket, designs_prefix} from the config. Uploads the HTML,
# upserts designs/manifest.json by slug, regenerates designs/index.html, and
# prints the live https://<site>/designs/<slug> URL.
#
# Uses `wrangler r2 object` (the logged-in OAuth session) — no S3 keys, no
# cross-account credential juggling. Run `wrangler login` if not authenticated.
set -euo pipefail

FILE="${1:?html file required}"
SLUG="${2:?slug required}"
TITLE="${3:?title required}"
STATUS="${4:-exploring}"
CONFIG="${5:-./.claude/design-ritual.json}"

[ -f "$FILE" ]   || { echo "✗ File not found: $FILE" >&2; exit 1; }
[ -f "$CONFIG" ] || { echo "✗ Config not found: $CONFIG (run the skill to create it)" >&2; exit 1; }

cfg() { python3 -c "import json,sys; print(json.load(open('$CONFIG'))['$1'])"; }
SITE=$(cfg site); BUCKET=$(cfg r2_bucket); PREFIX=$(cfg designs_prefix)

r2put() { npx wrangler r2 object put "$1" --file="$2" --content-type="$3" --remote >/dev/null; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "→ Uploading $FILE → r2://$BUCKET/${PREFIX}${SLUG}.html"
r2put "${BUCKET}/${PREFIX}${SLUG}.html" "$FILE" "text/html"

# Upsert manifest.json by slug (download if present, merge, re-upload).
npx wrangler r2 object get "${BUCKET}/${PREFIX}manifest.json" --file="$TMP/manifest.json" --remote >/dev/null 2>&1 \
  || echo "[]" > "$TMP/manifest.json"
DATE=$(date +%Y-%m-%d)
python3 - "$TMP/manifest.json" "$SLUG" "$TITLE" "$STATUS" "$DATE" <<'PY'
import json,sys
path,slug,title,status,date = sys.argv[1:6]
items=json.load(open(path))
items=[x for x in items if x.get("slug")!=slug]
items.append({"slug":slug,"title":title,"status":status,"date":date})
items.sort(key=lambda x:(x["date"],x["slug"]),reverse=True)
json.dump(items,open(path,"w"),indent=2)
PY
r2put "${BUCKET}/${PREFIX}manifest.json" "$TMP/manifest.json" "application/json"

# Regenerate index.html from the manifest.
python3 - "$TMP/manifest.json" "$TMP/index.html" "$SITE" <<'PY'
import json,sys,html
manifest,out,site = sys.argv[1:4]
items=json.load(open(manifest))
cards="".join(
 f'<a class=card href="/designs/{html.escape(i["slug"])}">'
 f'<span class=badge data-s="{html.escape(i["status"])}">{html.escape(i["status"])}</span>'
 f'<h2>{html.escape(i["title"])}</h2><time>{html.escape(i["date"])}</time></a>'
 for i in items) or "<p>No designs yet.</p>"
open(out,"w").write(f"""<!doctype html><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1">
<title>Designs · {html.escape(site)}</title>
<style>body{{font-family:system-ui;margin:0;padding:3rem 1.5rem;background:#0f1115;color:#e7e9ee}}
h1{{font-size:1.4rem;margin:0 0 1.5rem}}.grid{{display:grid;gap:1rem;max-width:780px;margin:0 auto;
grid-template-columns:repeat(auto-fill,minmax(220px,1fr))}}.card{{display:block;padding:1.25rem;border-radius:14px;
background:#1a1d25;color:inherit;text-decoration:none;border:1px solid #262a35;transition:.15s}}
.card:hover{{border-color:#3a86ff;transform:translateY(-2px)}}.card h2{{font-size:1rem;margin:.4rem 0 .2rem}}
time{{font-size:.8rem;color:#8b92a5}}.badge{{font-size:.65rem;text-transform:uppercase;letter-spacing:.05em;
padding:.15rem .5rem;border-radius:999px;background:#262a35;color:#8b92a5}}
.badge[data-s=shipped]{{background:#0f3d2e;color:#4ade80}}</style>
<h1>Designs · {html.escape(site)}</h1><div class=grid>{cards}</div>""")
PY
r2put "${BUCKET}/${PREFIX}index.html" "$TMP/index.html" "text/html"

echo "✓ Shipped: https://${SITE}/designs/${SLUG}"
echo "  Gallery: https://${SITE}/designs/"
