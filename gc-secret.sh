#!/usr/bin/env bash
# gc-secret — manage encrypted secrets in Golden Cloud.
#
# All filenames are relative to ~/golden-cloud/secrets/.
# Values are passed via stdin (never CLI args — args leak into shell history
# and process lists).
#
# Usage:
#   gc-secret list                              # show all secret files + sizes
#   gc-secret get <file>                        # print full decrypted file
#   gc-secret get <file> <KEY>                  # print single value
#   gc-secret set <file> <KEY>  < value         # set/update one key (stdin = value)
#   gc-secret put <file>        < plaintext     # create/replace whole file (stdin = plaintext)
#   gc-secret edit <file>                       # open in $EDITOR via sops
#   gc-secret rotate <file> <KEY>               # remove key, prompt for new value
#   gc-secret audit [N]                         # tail the last N audit entries (default 20)
#
# Provenance (why/who/where — recorded to secrets/AUDIT.md on every write):
#   --purpose "..."   short description of what this secret is for (optional but encouraged)
#   -p "..."          alias for --purpose
#   GC_PURPOSE=...    env var alternative
#   If none given and stdin IS a tty, you'll be prompted. If piped (AI workflow),
#   the script writes "(no purpose recorded)" and keeps going.
#
# Examples:
#   # Save a new API key with context:
#   echo "$NEW_KEY" | gc-secret set vendor-x.env API_KEY --purpose "Vendor X notify webhook"
#
#   # Create a fresh secret file from a local plaintext:
#   gc-secret put mailgun.env --purpose "outbound transactional email" < /tmp/mg.env
#
#   # Read one value:
#   SERVICE_KEY=$(gc-secret get p69-prod.env SUPABASE_SERVICE_ROLE_KEY)
#
#   # See who touched what, when:
#   gc-secret audit
#
# After any change the script commits + pushes automatically.
# Ciphertext + AUDIT.md only — never plaintext — reaches git.

set -euo pipefail

GC="${GC:-$HOME/golden-cloud}"
SECRETS="$GC/secrets"
AUDIT="$SECRETS/AUDIT.md"

die() { echo "✗ $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "$1 not installed"; }

# Parse optional --purpose/-p anywhere in the arg list; strip them out.
# Sets $purpose; leaves positional args in $ARGS array.
_parse_purpose() {
  purpose="${GC_PURPOSE:-}"
  ARGS=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --purpose|-p) purpose="${2:-}"; shift 2 ;;
      --purpose=*)  purpose="${1#--purpose=}"; shift ;;
      *)            ARGS+=("$1"); shift ;;
    esac
  done
}

_require_purpose() {
  # Called before a write. If --purpose wasn't set and stdin-after-value is a
  # tty (human at terminal), prompt. If piped (AI), allow but log sentinel.
  if [ -z "${purpose:-}" ]; then
    if [ -t 0 ]; then
      printf "  purpose (why is this secret being added? what's it for?): " >&2
      IFS= read -r purpose
    fi
    [ -z "$purpose" ] && purpose="(no purpose recorded)"
  fi
}

_who() {
  # "yan" from git, falls back to $USER; add host so multi-laptop is legible.
  local name host
  name="$(git -C "$GC" config user.name 2>/dev/null || echo "${USER:-unknown}")"
  host="$(scutil --get ComputerName 2>/dev/null || hostname -s 2>/dev/null || echo "unknown-host")"
  # Flag non-tty callers so we can see which writes came from an AI/script.
  local agent=""
  [ -t 1 ] || agent=" (ai/script)"
  printf '%s @ %s%s' "$name" "$host" "$agent"
}

_audit_append() {
  # $1 = action (set/put/edit/rotate/rm)
  # $2 = scope (file:KEY or file)
  local when action scope who line
  when="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  action="$1"
  scope="$2"
  who="$(_who)"
  line="- \`$when\` — **$action** \`$scope\` — _${who}_ — $purpose"

  if [ ! -f "$AUDIT" ]; then
    cat > "$AUDIT" <<'EOF'
# Golden Cloud — Secrets Audit Log

Every write to `secrets/*` appends a line here. Ciphertext only lives in the
corresponding files; this log records **who, when, what, why**.

Entries are chronological (newest appended to the bottom). Format:

```
- `<utc-iso8601>` — **<action>** `<scope>` — _<user @ host>_ — <purpose>
```

EOF
  fi
  printf '%s\n' "$line" >> "$AUDIT"
}

_commit() {
  # Stage both the secret and the audit log so they push atomically.
  cd "$GC"
  local changed=""
  [ -n "$(git status --porcelain -- "secrets/$file" 2>/dev/null)" ] && changed="1"
  [ -n "$(git status --porcelain -- "secrets/AUDIT.md" 2>/dev/null)" ] && changed="1"

  if [ -n "$changed" ]; then
    git add "secrets/$file" "secrets/AUDIT.md" 2>/dev/null || true
    git commit -m "gc-secret: $* — $purpose" --quiet || true
    git push --quiet 2>&1 | tail -1 || true
    echo "✓ $* ($purpose) → pushed" >&2
  else
    echo "  (no change)" >&2
  fi
}

need sops
need git
[ -d "$GC" ] || die "Golden Cloud not found at $GC"
[ -d "$SECRETS" ] || die "$SECRETS missing"

cmd="${1:-}"; shift || true

# Strip --purpose / -p from any command; sets $purpose and ARGS[].
_parse_purpose "$@"
set -- "${ARGS[@]-}"

case "$cmd" in
  list|ls)
    cd "$SECRETS"
    ls -la | tail -n +4 | awk '{print $NF, "("$5" bytes)"}' | grep -v '^\.gitkeep' | grep -v '^AUDIT\.md' || true
    ;;

  audit)
    n="${1:-20}"
    [ -f "$AUDIT" ] || die "no audit log yet"
    tail -n "$n" "$AUDIT"
    ;;

  get)
    file="${1:?usage: gc-secret get <file> [<KEY>]}"
    key="${2:-}"
    src="$SECRETS/$file"
    [ -f "$src" ] || die "no such secret: $file"
    if [ -n "$key" ]; then
      sops -d "$src" | awk -F= -v k="^${key}=" '$0 ~ k { sub(/^[^=]*=/, ""); gsub(/"/, ""); print; exit }'
    else
      sops -d "$src"
    fi
    ;;

  set)
    file="${1:?usage: echo VALUE | gc-secret set <file> <KEY> [--purpose \"why\"]}"
    key="${2:?KEY required}"
    dst="$SECRETS/$file"
    value="$(cat)"; value="${value%$'\n'}"
    [ -n "$value" ] || die "empty value on stdin — refusing to set"
    _require_purpose

    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT

    if [ -f "$dst" ]; then
      sops -d "$dst" > "$tmp"
      if grep -q "^${key}=" "$tmp"; then
        awk -F= -v k="$key" -v v="$value" 'BEGIN{done=0} $1==k {print k"="v; done=1; next} {print} END{if(!done) print k"="v}' "$tmp" > "$tmp.new"
        mv "$tmp.new" "$tmp"
      else
        printf '%s=%s\n' "$key" "$value" >> "$tmp"
      fi
    else
      printf '%s=%s\n' "$key" "$value" > "$tmp"
    fi

    mv "$tmp" "$dst"
    (cd "$GC" && sops --encrypt --in-place "secrets/$file")
    _audit_append "set" "$file:$key"
    _commit "set $key in $file"
    ;;

  put)
    file="${1:?usage: gc-secret put <file> [--purpose \"why\"] < plaintext}"
    dst="$SECRETS/$file"
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    cat > "$tmp"
    [ -s "$tmp" ] || die "empty stdin — refusing to put"
    _require_purpose
    mv "$tmp" "$dst"
    (cd "$GC" && sops --encrypt --in-place "secrets/$file")
    _audit_append "put" "$file"
    _commit "put $file"
    ;;

  edit)
    file="${1:?usage: gc-secret edit <file>}"
    dst="$SECRETS/$file"
    [ -f "$dst" ] || die "no such secret: $file (use 'put' to create one)"
    _require_purpose
    (cd "$GC" && sops "secrets/$file")
    _audit_append "edit" "$file"
    _commit "edit $file"
    ;;

  rotate)
    file="${1:?usage: gc-secret rotate <file> <KEY> [--purpose \"why\"]}"
    key="${2:?KEY required}"
    _require_purpose
    printf "paste new value for %s (input hidden): " "$key" >&2
    stty -echo 2>/dev/null
    IFS= read -r value
    stty echo 2>/dev/null
    printf '\n' >&2
    [ -n "$value" ] || die "empty value — refusing to rotate"
    # Call self with --purpose passed through so audit stays consistent.
    printf '%s' "$value" | GC_PURPOSE="$purpose" "$0" set "$file" "$key"
    echo "  ↳ remember: rotate the underlying secret at source (Vercel, Supabase, etc.)" >&2
    ;;

  help|-h|--help|"")
    sed -n '1,45p' "$0" | sed 's|^# \{0,1\}||'
    ;;

  *)
    die "unknown command: $cmd (try: gc-secret help)"
    ;;
esac
