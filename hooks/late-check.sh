#!/usr/bin/env bash
# nightowl late-check hook (UserPromptSubmit).
# If the local clock is inside the "late night" window, render the reminder
# template and inject it so Claude suggests wrapping up and offers /goodnight.
# Throttled so it nags at most once per N minutes.

set -euo pipefail

# Drain stdin (the hook payload) so the pipe never blocks. We don't need it.
cat >/dev/null 2>&1 || true

# Resolve our own directory so the template is found regardless of cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- config (override via env) ---------------------------------------------
START="${NIGHTOWL_START:-23}"       # window start hour (23 = 11pm)
END="${NIGHTOWL_END:-6}"            # window end hour, exclusive (06 = 6am)
THROTTLE_MIN="${NIGHTOWL_THROTTLE_MIN:-30}"   # min minutes between nags
TEMPLATE="${NIGHTOWL_TEMPLATE:-$SCRIPT_DIR/reminder.tmpl}"  # prompt template
# ---------------------------------------------------------------------------

# Minimal template engine: read a template file and replace every {{KEY}}
# with the value from the KEY=VALUE pairs passed after the path. Pure bash,
# no external deps — keeps the prompt copy out of this script.
render_template() {
  local file="$1"; shift
  [ -f "$file" ] || return 1
  local content pair key val
  content="$(cat "$file")"
  for pair in "$@"; do
    key="${pair%%=*}"
    val="${pair#*=}"
    content="${content//\{\{$key\}\}/$val}"
  done
  printf '%s\n' "$content"
}

# NIGHTOWL_FAKE_HOUR / NIGHTOWL_FAKE_NOW are test seams: they let the suite pin
# the clock deterministically. In normal use they are unset and we read `date`.
hour="${NIGHTOWL_FAKE_HOUR:-$(date +%-H)}"   # 0-23, no leading zero
now="${NIGHTOWL_FAKE_NOW:-$(date +%s)}"

# Is `hour` inside [START, END)? Handles wrap-around (e.g. 22 -> 5).
in_window() {
  if [ "$START" -le "$END" ]; then
    [ "$hour" -ge "$START" ] && [ "$hour" -lt "$END" ]
  else
    [ "$hour" -ge "$START" ] || [ "$hour" -lt "$END" ]
  fi
}

in_window || exit 0

# Throttle via a state file in the OS temp dir.
state="${TMPDIR:-/tmp}/nightowl-last-nag"
if [ -f "$state" ]; then
  last=$(cat "$state" 2>/dev/null || echo 0)
  delta=$(( now - last ))
  if [ "$delta" -lt $(( THROTTLE_MIN * 60 )) ]; then
    exit 0
  fi
fi

clock=$(date +%H:%M)

# Render the reminder; only mark the throttle once we have output to show.
# A missing/unreadable template must never break the user's prompt.
if rendered=$(render_template "$TEMPLATE" "CLOCK=$clock"); then
  echo "$now" > "$state"
  # Anything printed to stdout on exit 0 is injected as context for the turn.
  printf '%s\n' "$rendered"
fi
