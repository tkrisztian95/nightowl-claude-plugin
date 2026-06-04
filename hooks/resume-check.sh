#!/usr/bin/env bash
# nightowl resume-check hook (SessionStart).
# If a recent /goodnight handoff is sitting in ./.nightowl, inject a one-line
# pointer so Claude reminds the user they can /goodmorning to resume. Surfaces
# at most once per handoff (a marker file dedupes repeat sessions). Also prunes
# stale handoffs so .nightowl/ doesn't grow forever. Never breaks the session.

set -uo pipefail

# Drain stdin (the hook payload) so the pipe never blocks. We don't need it.
cat >/dev/null 2>&1 || true

# --- config (override via env) ---------------------------------------------
DIR="${NIGHTOWL_DIR:-.nightowl}"                       # handoff directory (cwd)
MAX_AGE_DAYS="${NIGHTOWL_RESUME_MAX_AGE_DAYS:-3}"      # don't surface older than this
KEEP_DAYS="${NIGHTOWL_HANDOFF_KEEP_DAYS:-14}"         # prune handoffs older than this
# ---------------------------------------------------------------------------

# Nothing to do if this project has no handoff folder.
[ -d "$DIR" ] || exit 0

# NIGHTOWL_FAKE_NOW is a test seam: pin "now" deterministically. Unset normally.
now="${NIGHTOWL_FAKE_NOW:-$(date +%s)}"

# Portable mtime (epoch seconds): BSD/macOS `stat -f`, GNU/Linux `stat -c`.
file_mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null; }

# --- prune stale handoffs --------------------------------------------------
# .nightowl/ is git-ignored, ephemeral, per-day — safe to trim old files.
keep_secs=$(( KEEP_DAYS * 86400 ))
for f in "$DIR"/handoff-*.md; do
  [ -e "$f" ] || continue   # glob matched nothing
  m="$(file_mtime "$f")"; [ -n "$m" ] || continue
  if [ $(( now - m )) -gt "$keep_secs" ]; then
    rm -f "$f" 2>/dev/null || true
  fi
done

# --- find the newest surviving handoff -------------------------------------
# Dates (and the -HHMM suffix) sort lexically, so the last line is newest.
# Our filenames are controlled (handoff-YYYY-MM-DD-HHMM.md), so ls is safe here.
# shellcheck disable=SC2012
newest="$(ls -1 "$DIR"/handoff-*.md 2>/dev/null | sort | tail -1)"
[ -n "$newest" ] || exit 0

# Freshness gate: skip a handoff that's already older than MAX_AGE_DAYS (e.g. an
# old repo reopened weeks later) — no point nagging about ancient work.
m="$(file_mtime "$newest")"; [ -n "$m" ] || exit 0
if [ $(( now - m )) -gt $(( MAX_AGE_DAYS * 86400 )) ]; then
  exit 0
fi

# Dedup: surface a given handoff only once. The marker stores the path we last
# pointed at; if it still matches the newest, stay quiet this session.
marker="$DIR/.resume-seen"
if [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$newest" ]; then
  exit 0
fi
printf '%s' "$newest" > "$marker" 2>/dev/null || true

# Human-friendly date from the filename: handoff-2026-06-03-2330.md -> 2026-06-03.
base="$(basename "$newest" .md)"; base="${base#handoff-}"
when="${base:0:10}"

# Anything printed to stdout on exit 0 is injected as context for the session.
printf '%s\n' "<nightowl-resume>
A /goodnight handoff from ${when} is waiting in ${DIR}/. Before the user's
first request, add ONE short, friendly line letting them know the handoff
exists and they can run /goodmorning to resume where they left off. Keep it to
a single sentence, then proceed normally. (Shown once per handoff.)
</nightowl-resume>"

exit 0
