#!/usr/bin/env bash
# nightowl statusline segment.
# Prints a small "late night" owl badge under the Claude Code input when the
# local clock is inside the late-night window. Composable: if
# NIGHTOWL_BASE_STATUSLINE is set to another statusline command, this runs it
# (forwarding Claude's session JSON on stdin) and prepends the owl, so you keep
# whatever dashboard you already had.
#
# Wire it as your statusLine command in settings.json. See the README.

set -uo pipefail

# Claude Code feeds session JSON on stdin. We don't parse it for the owl, but a
# wrapped base statusline may want it, so capture it once and forward it.
payload="$(cat)"

# --- config (override via env; mirror the hook's window) -------------------
START="${NIGHTOWL_START:-23}"       # window start hour (23 = 11pm)
END="${NIGHTOWL_END:-6}"            # window end hour, exclusive (06 = 6am)
BADGE="${NIGHTOWL_BADGE:-🦉 late night · /roost}"
# ---------------------------------------------------------------------------

# Test seam: pin the hour deterministically (unset in normal use).
hour="${NIGHTOWL_FAKE_HOUR:-$(date +%-H)}"

in_window() {
  if [ "$START" -le "$END" ]; then
    [ "$hour" -ge "$START" ] && [ "$hour" -lt "$END" ]
  else
    [ "$hour" -ge "$START" ] || [ "$hour" -lt "$END" ]
  fi
}

# Run a wrapped base statusline, if configured, forwarding the session JSON.
# The command comes from the user's own settings, so it's trusted config.
base=""
if [ -n "${NIGHTOWL_BASE_STATUSLINE:-}" ]; then
  base="$(printf '%s' "$payload" | bash -c "$NIGHTOWL_BASE_STATUSLINE" 2>/dev/null)" || base=""
fi

owl=""
in_window && owl="$BADGE"

# Compose: owl badge first, then whatever the base produced.
if [ -n "$owl" ] && [ -n "$base" ]; then
  printf '%s  %s\n' "$owl" "$base"
elif [ -n "$owl" ]; then
  printf '%s\n' "$owl"
else
  printf '%s\n' "$base"
fi
