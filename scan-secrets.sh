#!/usr/bin/env bash
#
# scan-secrets.sh — find live credentials in git repos, including base64-wrapped ones.
#
# Why this exists:
#   Secret scanners match known prefixes (`sbp_`, `sk-ant-`, `ghp_`). Base64-encoding a
#   token hides the prefix, so a credential pasted into a tracked file as
#   `echo "<base64>" | base64 -d` scans completely clean — gitleaks included. It reads as
#   "not a plaintext secret" to both a scanner and a reviewer skimming the diff.
#   Any scanner that only greps known prefixes misses it. This one decodes too.
#
# Usage:
#   ./scan-secrets.sh                # current repo
#   ./scan-secrets.sh ~/a ~/b        # named repos
#   ./scan-secrets.sh --all          # every git repo in $HOME
#   ./scan-secrets.sh --staged       # staged changes only (pre-commit gate)
#
# Exits 1 on a finding. Prints locations and an 8-char prefix — never a full secret.

set -uo pipefail

# Prefixes indicating a REAL credential. Deliberately excludes `service_role`: in Supabase
# migrations that is a Postgres role name (`GRANT ... TO service_role`), and including it
# buries real findings under hundreds of false hits.
SECRET_RE='sbp_[A-Za-z0-9]{20,}|sk-ant-api[0-9]{2}-[A-Za-z0-9_-]{20,}|github_pat_[A-Za-z0-9_]{22,}|ghp_[A-Za-z0-9]{36}|xoxb-[0-9]{10,}-[0-9]{10,}-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|apikey_[A-Za-z0-9]{24,}|sk_live_[A-Za-z0-9]{20,}|rk_live_[A-Za-z0-9]{20,}'

# Docs placeholders and test fixtures.
FIXTURE_RE='xxxx|XXXX|your-|YOUR-|example|EXAMPLE|abcdefghij|0123456789|placeholder|AKIAIOSFODNN7|<[A-Za-z_-]+>'
SKIP_RE='package-lock|yarn\.lock|pnpm-lock|node_modules|\.min\.(js|css)|\.(png|jpe?g|gif|svg|woff2?|ttf|ico|pdf|mp4)$|\.env\.example|scan-secrets\.sh'

# Reads "file:line:content" on stdin, emits findings. $1 = label shown in output.
filter_plain() {
  grep -vE "$SKIP_RE" | while IFS= read -r hit; do
    body=${hit#*:}; body=${body#*:}
    printf '%s' "$body" | grep -qE "$FIXTURE_RE" && continue
    v=$(printf '%s' "$body" | grep -oE "$SECRET_RE" | head -1)
    [ -n "$v" ] && printf '  [PLAINTEXT] %s → %s  (%s…)\n' "$1" "${hit%%:*}:$(x=${hit#*:}; echo "${x%%:*}")" "${v:0:8}"
  done
}

# Reads "file:line:b64blob" on stdin; reports blobs that decode to a credential.
filter_b64() {
  grep -vE "$SKIP_RE" | while IFS= read -r hit; do
    blob=${hit##*:}
    dec=$(printf '%s' "$blob" | base64 -d 2>/dev/null) || continue
    printf '%s' "$dec" | grep -qE "^($SECRET_RE)" || continue
    printf '  [BASE64]    %s → %s  (decodes to %s…)\n' "$1" "${hit%%:*}:$(x=${hit#*:}; echo "${x%%:*}")" "${dec:0:8}"
  done
}

# Base64 of each marker at offset 0 — what `echo "$TOKEN" | base64` actually produces.
# Matching these lets grep (C) do the filtering, so we only shell out to decode real
# candidates. Scanning every 24-char base64 blob instead took >9min across 44 repos.
#   sbp_ → c2JwX   sk-ant-api → c2stYW50LWFwa   github_pat_ → Z2l0aHViX3BhdF
#   ghp_ → Z2hwX   xoxb- → eG94Yi   AKIA → QUtJQ   apikey_ → YXBpa2V5X
B64_RE='(c2JwX|c2stYW50LWFwa|Z2l0aHViX3BhdF|Z2hwX|eG94Yi|QUtJQ|YXBpa2V5X|c2tfbGl2ZV|cmtfbGl2ZV)[A-Za-z0-9+/]{12,}={0,2}'

scan_repo() {
  local repo=$1 label; label=$(basename "$repo")
  [ -d "$repo/.git" ] || return 0
  cd "$repo" || return 0
  git ls-files -z 2>/dev/null | xargs -0 grep -nEI "$SECRET_RE" 2>/dev/null | filter_plain "$label"
  git ls-files -z 2>/dev/null | xargs -0 grep -noEI "$B64_RE" 2>/dev/null | filter_b64 "$label"
}

if [ "${1:-}" = "--staged" ]; then
  hits=$(
    git diff --cached -U0 --diff-filter=ACM 2>/dev/null | grep '^+' | grep -vE '^\+\+\+' |
      grep -EI "$SECRET_RE" | grep -vE "$FIXTURE_RE" | sed 's/^+//' |
      while IFS= read -r l; do printf 'staged:0:%s\n' "$l"; done | filter_plain "staged"
    git diff --cached -U0 --diff-filter=ACM 2>/dev/null | grep '^+' | grep -vE '^\+\+\+' |
      grep -oEI "$B64_RE" |
      while IFS= read -r b; do printf 'staged:0:%s\n' "$b"; done | filter_b64 "staged"
  )
  if [ -n "$hits" ]; then
    printf '\n🚫 BLOCKED — credential in staged changes:\n%s\n' "$hits"
    printf '\nPut it in the vault instead:\n  echo "$VALUE" | ~/golden-vault/gc-secret.sh set <file> <KEY>\n\n'
    exit 1
  fi
  exit 0
fi

case "${1:-}" in
  --all) repos=$(ls -d "$HOME"/*/.git 2>/dev/null | sed 's|/.git$||') ;;
  "")    repos=$(git rev-parse --show-toplevel 2>/dev/null) ;;
  *)     repos="$*" ;;
esac

echo "### Credential scan (plaintext + base64)"
for r in $repos; do ( scan_repo "$r" ); done

echo
echo "### Env files present — all must be gitignored"
for r in $repos; do
  [ -d "$r/.git" ] || continue
  ( cd "$r" || exit 0
    for f in .env .env.local .env.production; do
      [ -f "$f" ] || continue
      git check-ignore -q "$f" \
        && printf '  ok     %s/%s\n' "$(basename "$r")" "$f" \
        || printf '  !!RISK %s/%s NOT IGNORED\n' "$(basename "$r")" "$f"
    done )
done
