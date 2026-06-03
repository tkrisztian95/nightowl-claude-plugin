#!/usr/bin/env bash
# Tests for hooks/late-check.sh — plain bash, no external deps (no bats).
# Run:  bash tests/late-check.test.sh
#
# Clock and time are pinned via the NIGHTOWL_FAKE_HOUR / NIGHTOWL_FAKE_NOW
# test seams so window, wrap-around, and throttle logic are deterministic.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/../hooks/late-check.sh"

pass=0
fail=0

# Each test gets its own throttle dir so cases never bleed into each other.
fresh_tmp() { mktemp -d "${TMPDIR:-/tmp}/nightowl-test.XXXXXX"; }

# run <name> <expect: fire|silent> <env assignments...>
# Asserts both the exit code (always 0) and whether the reminder was emitted.
run() {
  local name="$1" expect="$2"; shift 2
  local out rc
  out="$(env "$@" bash "$HOOK" </dev/null 2>/dev/null)"; rc=$?

  if [ "$rc" -ne 0 ]; then
    printf 'FAIL  %s — exit %d (hooks must always exit 0)\n' "$name" "$rc"
    fail=$((fail + 1)); return
  fi

  local fired=silent
  [ -n "$out" ] && fired=fire

  if [ "$fired" != "$expect" ]; then
    printf 'FAIL  %s — expected %s, got %s\n' "$name" "$expect" "$fired"
    fail=$((fail + 1)); return
  fi

  # When it fires, the template must be fully rendered: reminder present and
  # no unsubstituted {{...}} placeholders left behind.
  if [ "$fired" = fire ]; then
    if [[ "$out" != *"<nightowl-reminder>"* ]]; then
      printf 'FAIL  %s — output missing reminder tag\n' "$name"
      fail=$((fail + 1)); return
    fi
    if [[ "$out" == *'{{'* ]]; then
      printf 'FAIL  %s — unrendered placeholder in output\n' "$name"
      fail=$((fail + 1)); return
    fi
  fi

  printf 'ok    %s\n' "$name"
  pass=$((pass + 1))
}

# --- window detection ------------------------------------------------------
run "inside window (02:00, 0-6)"      fire   NIGHTOWL_FAKE_HOUR=2  NIGHTOWL_START=0 NIGHTOWL_END=6 "TMPDIR=$(fresh_tmp)"
run "outside window (12:00, 0-6)"     silent NIGHTOWL_FAKE_HOUR=12 NIGHTOWL_START=0 NIGHTOWL_END=6 "TMPDIR=$(fresh_tmp)"
run "boundary start (00:00, 0-6)"     fire   NIGHTOWL_FAKE_HOUR=0  NIGHTOWL_START=0 NIGHTOWL_END=6 "TMPDIR=$(fresh_tmp)"
run "boundary end excl (06:00, 0-6)"  silent NIGHTOWL_FAKE_HOUR=6  NIGHTOWL_START=0 NIGHTOWL_END=6 "TMPDIR=$(fresh_tmp)"

# --- wrap-around window (22:00 -> 05:00) -----------------------------------
run "wrap late (23:00, 22-5)"         fire   NIGHTOWL_FAKE_HOUR=23 NIGHTOWL_START=22 NIGHTOWL_END=5 "TMPDIR=$(fresh_tmp)"
run "wrap early (03:00, 22-5)"        fire   NIGHTOWL_FAKE_HOUR=3  NIGHTOWL_START=22 NIGHTOWL_END=5 "TMPDIR=$(fresh_tmp)"
run "wrap daytime (10:00, 22-5)"      silent NIGHTOWL_FAKE_HOUR=10 NIGHTOWL_START=22 NIGHTOWL_END=5 "TMPDIR=$(fresh_tmp)"

# --- throttle --------------------------------------------------------------
throttle_dir="$(fresh_tmp)"
run "throttle: first nag"  fire \
  NIGHTOWL_FAKE_HOUR=2 NIGHTOWL_FAKE_NOW=1000 NIGHTOWL_START=0 NIGHTOWL_END=6 NIGHTOWL_THROTTLE_MIN=30 "TMPDIR=$throttle_dir"
run "throttle: 5 min later silent" silent \
  NIGHTOWL_FAKE_HOUR=2 NIGHTOWL_FAKE_NOW=1300 NIGHTOWL_START=0 NIGHTOWL_END=6 NIGHTOWL_THROTTLE_MIN=30 "TMPDIR=$throttle_dir"
run "throttle: 31 min later fires"  fire \
  NIGHTOWL_FAKE_HOUR=2 NIGHTOWL_FAKE_NOW=2861 NIGHTOWL_START=0 NIGHTOWL_END=6 NIGHTOWL_THROTTLE_MIN=30 "TMPDIR=$throttle_dir"

# --- template handling -----------------------------------------------------
# Custom template renders its own placeholders.
custom_dir="$(fresh_tmp)"
custom_tmpl="$custom_dir/custom.tmpl"
printf '<nightowl-reminder>now {{CLOCK}}</nightowl-reminder>\n' > "$custom_tmpl"
run "custom template renders" fire \
  NIGHTOWL_FAKE_HOUR=2 NIGHTOWL_START=0 NIGHTOWL_END=6 "NIGHTOWL_TEMPLATE=$custom_tmpl" "TMPDIR=$(fresh_tmp)"

# Missing template: must stay silent and still exit 0 (never break the prompt).
missing_dir="$(fresh_tmp)"
run "missing template is graceful" silent \
  NIGHTOWL_FAKE_HOUR=2 NIGHTOWL_START=0 NIGHTOWL_END=6 "NIGHTOWL_TEMPLATE=/no/such/file.tmpl" "TMPDIR=$missing_dir"
# ...and a missing template must not write throttle state.
if [ -f "$missing_dir/nightowl-last-nag" ]; then
  printf 'FAIL  missing template wrote throttle state\n'; fail=$((fail + 1))
else
  printf 'ok    missing template leaves no throttle state\n'; pass=$((pass + 1))
fi

# --- summary ---------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
