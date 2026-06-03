#!/usr/bin/env bash
# nightowl late-check hook (UserPromptSubmit).
# If the local clock is inside the "late night" window, inject a gentle
# reminder asking Claude to suggest wrapping up and offer /goodnight.
# Throttled so it nags at most once per window per N minutes.

set -euo pipefail

# Drain stdin (the hook payload) so the pipe never blocks. We don't need it.
cat >/dev/null 2>&1 || true

# --- config (override via env) ---------------------------------------------
START="${NIGHTOWL_START:-0}"        # window start hour (00 = midnight)
END="${NIGHTOWL_END:-6}"            # window end hour, exclusive (06 = 6am)
THROTTLE_MIN="${NIGHTOWL_THROTTLE_MIN:-30}"   # min minutes between nags
# ---------------------------------------------------------------------------

hour=$(date +%-H)   # 0-23, no leading zero
now=$(date +%s)

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
echo "$now" > "$state"

clock=$(date +%H:%M)

# Anything printed to stdout on exit 0 is injected as context for the turn.
cat <<EOF
<nightowl-reminder>
It is ${clock} — inside the user's late-night window. Before diving into the
request, add ONE short, friendly line suggesting they consider wrapping up and
continuing tomorrow, and mention they can run /goodnight to save a handoff
summary. Keep it to a single sentence, do not lecture, then proceed normally
with their actual request. (This reminder is rate-limited; do not repeat it if
you have already nudged recently.)
</nightowl-reminder>
EOF
