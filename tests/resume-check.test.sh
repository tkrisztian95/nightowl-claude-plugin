#!/usr/bin/env bash
# Tests for hooks/resume-check.sh — plain bash, no external deps (no bats).
# Run:  bash tests/resume-check.test.sh
#
# "Now" is pinned via NIGHTOWL_FAKE_NOW and file mtimes are set with set_mtime,
# so freshness, dedup, and pruning logic are deterministic.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/../hooks/resume-check.sh"

pass=0
fail=0

NOW=1700000000          # fixed "now" epoch
DAY=86400

fresh_dir() { mktemp -d "${TMPDIR:-/tmp}/nightowl-resume.XXXXXX"; }

# Set a file's mtime to an absolute epoch — portable across GNU and BSD/macOS.
set_mtime() {
  local file="$1" epoch="$2" ts
  ts="$(date -r "$epoch" +%Y%m%d%H%M.%S 2>/dev/null \
        || date -d "@$epoch" +%Y%m%d%H%M.%S 2>/dev/null)"
  touch -t "$ts" "$file"
}

# check <name> <expect: fire|silent> <dir> — runs the hook against $dir and
# asserts exit 0 and whether a <nightowl-resume> block was emitted.
check() {
  local name="$1" expect="$2" dir="$3"
  local out rc fired=silent
  out="$(env "NIGHTOWL_DIR=$dir" "NIGHTOWL_FAKE_NOW=$NOW" bash "$HOOK" </dev/null 2>/dev/null)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    printf 'FAIL  %s — exit %d (hooks must always exit 0)\n' "$name" "$rc"
    fail=$((fail + 1)); return
  fi
  [[ "$out" == *"<nightowl-resume>"* ]] && fired=fire
  if [ "$fired" != "$expect" ]; then
    printf 'FAIL  %s — expected %s, got %s\n  out: %q\n' "$name" "$expect" "$fired" "$out"
    fail=$((fail + 1)); return
  fi
  printf 'ok    %s\n' "$name"; pass=$((pass + 1))
}

# --- no handoff folder -----------------------------------------------------
check "missing .nightowl dir is silent" silent "$(fresh_dir)/nope"

# --- empty folder ----------------------------------------------------------
check "empty folder is silent" silent "$(fresh_dir)"

# --- fresh handoff: surfaces once, then deduped ----------------------------
d="$(fresh_dir)"
touch "$d/handoff-2026-06-03-2330.md"
set_mtime "$d/handoff-2026-06-03-2330.md" $(( NOW - 3600 ))   # 1h ago
check "fresh handoff surfaces"          fire   "$d"
check "second run deduped (marker set)" silent "$d"

# --- stale handoff beyond MAX_AGE_DAYS (default 3) is not surfaced ----------
d="$(fresh_dir)"
touch "$d/handoff-2026-05-20-2330.md"
set_mtime "$d/handoff-2026-05-20-2330.md" $(( NOW - 10 * DAY ))
check "stale handoff is silent" silent "$d"

# --- pruning: old (>KEEP_DAYS=14) removed, recent kept and surfaced ---------
d="$(fresh_dir)"
old="$d/handoff-2026-05-01-1200.md"
new="$d/handoff-2026-06-03-2330.md"
touch "$old" "$new"
set_mtime "$old" $(( NOW - 20 * DAY ))   # prunable
set_mtime "$new" $(( NOW - 1 * DAY ))    # fresh
check "prune keeps fresh, surfaces it" fire "$d"
if [ -e "$old" ]; then
  printf 'FAIL  prune removed stale handoff — %s still exists\n' "$old"; fail=$((fail + 1))
else
  printf 'ok    prune removed stale handoff\n'; pass=$((pass + 1))
fi
if [ -e "$new" ]; then
  printf 'ok    prune kept recent handoff\n'; pass=$((pass + 1))
else
  printf 'FAIL  prune wrongly removed recent handoff — %s gone\n' "$new"; fail=$((fail + 1))
fi

# --- summary ---------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
