#!/usr/bin/env bash
# Tests for statusline/nightowl-statusline.sh — plain bash, no deps.
# Run:  bash tests/statusline.test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SL="$HERE/../statusline/nightowl-statusline.sh"

pass=0
fail=0

# assert <name> <expected-stdout> <env assignments...>
assert() {
  local name="$1" expected="$2"; shift 2
  local out
  out="$(env "$@" bash "$SL" </dev/null 2>/dev/null)"
  if [ "$out" = "$expected" ]; then
    printf 'ok    %s\n' "$name"; pass=$((pass + 1))
  else
    printf 'FAIL  %s\n  expected: %q\n  got:      %q\n' "$name" "$expected" "$out"
    fail=$((fail + 1))
  fi
}

OWL="🦉 late night · /roost"

# Late: owl badge shows (no base configured).
assert "late shows owl"        "$OWL" NIGHTOWL_FAKE_HOUR=2  NIGHTOWL_START=0 NIGHTOWL_END=6 NIGHTOWL_BASE_STATUSLINE=
# Daytime: nothing (no base, not late).
assert "daytime empty"         ""     NIGHTOWL_FAKE_HOUR=12 NIGHTOWL_START=0 NIGHTOWL_END=6 NIGHTOWL_BASE_STATUSLINE=

# Base passthrough when not late: only base shows.
assert "daytime base only"     "DASH" NIGHTOWL_FAKE_HOUR=12 NIGHTOWL_START=0 NIGHTOWL_END=6 "NIGHTOWL_BASE_STATUSLINE=printf DASH"
# Late + base: owl prepended to base, two spaces between.
assert "late owl + base"       "$OWL  DASH" NIGHTOWL_FAKE_HOUR=2 NIGHTOWL_START=0 NIGHTOWL_END=6 "NIGHTOWL_BASE_STATUSLINE=printf DASH"

# Custom badge text honored.
assert "custom badge"          "ZZZ"  NIGHTOWL_FAKE_HOUR=2 NIGHTOWL_START=0 NIGHTOWL_END=6 NIGHTOWL_BADGE=ZZZ NIGHTOWL_BASE_STATUSLINE=
# Wrap-around window covers early hours.
assert "wrap early shows owl"  "$OWL" NIGHTOWL_FAKE_HOUR=3 NIGHTOWL_START=22 NIGHTOWL_END=5 NIGHTOWL_BASE_STATUSLINE=

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
