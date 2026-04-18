#!/bin/sh
input=$(cat)

# --- Git branch + worktree indicator ---
cwd=$(echo "$input" | jq -r '.cwd // ""')
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -z "$branch" ]; then
  git_part=""
else
  # Dirty indicator: any staged or unstaged changes
  dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -1)
  if [ -n "$dirty" ]; then
    dirty_label=" ●"
  else
    dirty_label=""
  fi

  git_part="⎇ ${branch}${dirty_label}"
fi

# --- Context usage (session %) ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  pct_label="$(echo "$used_pct" | awk '{printf "%.0f%%", $1}')"
else
  pct_label="0%"
fi

# --- Weekly plan usage + reset ---
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$week_pct" ]; then
  week_label=$(printf "7d: %.0f%%" "$week_pct")
  if [ -n "$week_resets" ]; then
    # e.g. "Apr 17 2pm" — lowercase am/pm, no leading zero on hour
    # Relative: "3d 4h", "5h 20m", "45m"
    now=$(date +%s)
    delta=$((week_resets - now))
    if [ "$delta" -gt 0 ]; then
      d=$((delta / 86400))
      h=$(((delta % 86400) / 3600))
      m=$(((delta % 3600) / 60))
      if [ "$d" -gt 0 ]; then
        reset_fmt="${d}d ${h}h"
      elif [ "$h" -gt 0 ]; then
        reset_fmt="${h}h ${m}m"
      else
        reset_fmt="${m}m"
      fi
      week_label="${week_label} · ${reset_fmt}"
    fi
  fi
else
  week_label=""
fi

# --- Per-tab quote (stable for this session, unique per new tab) ---
quotes_file="$HOME/.claude/quotes.txt"
quote=""
if [ -f "$quotes_file" ]; then
  quote_count=$(grep -c . "$quotes_file" 2>/dev/null)
  if [ -n "$quote_count" ] && [ "$quote_count" -gt 0 ]; then
    session_id=$(echo "$input" | jq -r '.session_id // empty')
    if [ -n "$session_id" ]; then
      # Hash session_id → stable index. Different tab = different session_id = different quote.
      seed=$(printf "%s" "$session_id" | cksum | awk '{print $1}')
    else
      # Fallback: 15-min bucket if session_id missing
      seed=$(( $(date +%s) / 900 ))
    fi
    idx=$(( (seed % quote_count) + 1 ))
    quote=$(sed -n "${idx}p" "$quotes_file")
  fi
fi

# --- Cmd-clickable lookup link (OSC 8 hyperlink, shows as 🔎) ---
link_part=""
if [ -n "$quote" ]; then
  # Strip leading emoji (everything up to first space) for cleaner search
  search_text=$(printf "%s" "$quote" | sed 's/^[^ ]* //')
  encoded=$(printf "%s" "$search_text" | jq -sRr @uri 2>/dev/null)
  if [ -n "$encoded" ]; then
    lookup_url="https://www.google.com/search?q=${encoded}"
    esc=$(printf '\033')
    link_part=" ${esc}]8;;${lookup_url}${esc}\\🔎${esc}]8;;${esc}\\"
  fi
fi

# --- Assemble output ---
line="${git_part:+${git_part} | }${pct_label}"
if [ -n "$week_label" ]; then
  line="${line} | ${week_label}"
fi
if [ -n "$quote" ]; then
  line="${line} ✦ ${quote}${link_part}"
fi

printf "%s" "$line"
