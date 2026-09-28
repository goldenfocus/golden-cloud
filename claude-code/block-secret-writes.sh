#!/usr/bin/env bash
#
# block-secret-writes.sh — Claude Code PreToolUse hook.
# Refuses any Write/Edit whose content carries a live credential, plaintext or base64.
#
# Blocking at the write is the only chokepoint every repo shares. A global git pre-commit
# hook is not reliable: any repo that sets its own `core.hooksPath` (husky, lefthook, a
# `.githooks` dir) silently overrides it, and gitleaks does not match base64-wrapped
# prefixes at all. Catching it before it reaches disk avoids both gaps.
#
# Install (Tier A — needs Yan's approval), in ~/.claude/settings.json:
#   "hooks": { "PreToolUse": [ {
#       "matcher": "Write|Edit",
#       "hooks": [ { "type": "command",
#                    "command": "~/golden-cloud/claude-code/block-secret-writes.sh" } ]
#   } ] }
#
# Exit 2 = block the tool call; stderr is shown to Claude so it can self-correct.

set -uo pipefail

SECRET_RE='sbp_[A-Za-z0-9]{20,}|sk-ant-api[0-9]{2}-[A-Za-z0-9_-]{20,}|github_pat_[A-Za-z0-9_]{22,}|ghp_[A-Za-z0-9]{36}|xoxb-[0-9]{10,}-[0-9]{10,}-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|apikey_[A-Za-z0-9]{24,}|sk_live_[A-Za-z0-9]{20,}|rk_live_[A-Za-z0-9]{20,}'
FIXTURE_RE='xxxx|XXXX|your-|YOUR-|example|EXAMPLE|abcdefghij|0123456789|placeholder|AKIAIOSFODNN7|<[A-Za-z_-]+>'

payload=$(cat)
command -v jq >/dev/null 2>&1 || exit 0   # no jq: fail open rather than block all edits

path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')

# .env files are the correct home for a live key and are gitignored — let those through.
case "$path" in *.env|*.env.local|*.env.production|*.env.development) exit 0 ;; esac

# Everything the tool would write: Write.content, Edit.new_string.
content=$(printf '%s' "$payload" | jq -r '
  [ .tool_input.content?, .tool_input.new_string?, (.tool_input.edits? // [])[]?.new_string? ]
  | map(select(. != null)) | join("\n")')
[ -z "$content" ] && exit 0

flag() {
  cat >&2 <<EOF
BLOCKED: this write contains what looks like a live credential ($1).

Never put a real secret in a tracked file — not even base64-encoded. Encoding it does not
make it safe, it just makes it invisible to the scanners that would have caught it.

Do this instead:
  echo "\$VALUE" | ~/golden-vault/gc-secret.sh set <file> <KEY>   # encrypted, committed
  TOKEN=\$(sops -d ~/golden-vault/secrets/<file> | grep KEY | cut -d= -f2)

If this is a placeholder, make it obviously fake: use \`your-key-here\` or \`sk-ant-xxxx\`.
EOF
  exit 2
}

# Plaintext.
hit=$(printf '%s' "$content" | grep -oE "$SECRET_RE" | grep -vE "$FIXTURE_RE" | head -1 || true)
[ -n "$hit" ] && flag "plaintext ${hit:0:8}…"

# Base64-wrapped — the case stock scanners miss.
while IFS= read -r blob; do
  [ -z "$blob" ] && continue
  dec=$(printf '%s' "$blob" | base64 -d 2>/dev/null) || continue
  printf '%s' "$dec" | grep -qE "^($SECRET_RE)" && flag "base64-encoded ${dec:0:8}…"
done < <(printf '%s' "$content" |
  grep -oE '(c2JwX|c2stYW50LWFwa|Z2l0aHViX3BhdF|Z2hwX|eG94Yi|QUtJQ|YXBpa2V5X|c2tfbGl2ZV|cmtfbGl2ZV)[A-Za-z0-9+/]{12,}={0,2}' |
  head -50)

exit 0
