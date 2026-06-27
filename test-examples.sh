#!/bin/bash
# Validation harness: guard rails + esphome config + esphome compile
# Must be run from repo root (where esphome.sh lives)
#
# -e: abort on any unguarded command failure (this harness is the repo's only
#     automated safety net — failures must be loud, not swallowed).
# -u: treat unset variables as errors.
# -o pipefail: a failure anywhere in a pipeline fails the whole pipeline, so a
#     mid-pipe grep/sed error in a guard cannot masquerade as a passing "OK".
# Guards whose ZERO-match is a NORMAL passing condition are made -e-safe with an
# explicit `if grep` (Guard 1) or a trailing `|| true` (Guard 2).
set -euo pipefail

[[ -x "./esphome.sh" ]] || { echo "ERROR: run from repo root"; exit 1; }

shopt -s nullglob   # unmatched globs expand to empty, not literal pattern

PASS=0
FAIL=0
FAILURES=()

# Guard 1: no !secret in packages/
echo "=== Guard: no !secret in packages/ ==="
if grep -r '!secret' packages/ 2>/dev/null; then
  echo "FAIL: !secret found in packages/ — packages must not contain !secret"
  exit 1
fi
echo "OK — no !secret in packages/"

# Guard 2: no duplicate ids across package files
#
# Robustly detect a shared `id:` declared in MORE THAN ONE package file. Handles
# every common ESPHome id idiom:
#   own-line single-space unquoted   id: foo
#   inline list form               - id: foo
#   multi-space                      id:    foo
#   quoted                           id: "foo"   id: 'foo'
#
# The id is captured as the FIRST field with a TAB separator. Paths contain `/`
# but never a literal TAB, so `awk -F'\t'` can never mistake the path for the id.
# A `sort -u` on the id<TAB>file pair collapses the same id repeated within a
# SINGLE file (NOT a collision); only ids appearing across >1 file are reported.
#
# Variant-suffix convention (D6):
# Package files that differ ONLY by a trailing variant suffix (-i2c, -neopixel)
# before the .yaml extension are SIBLING packages (e.g. grove-led-driver-i2c.yaml
# and grove-led-driver-neopixel.yaml). A consumer imports exactly ONE of them, so
# shared ids (e.g. aqi_strip, driver_button) are intentional and MUST NOT be flagged
# as duplicates. The sed step below normalises the file path by stripping a -i2c or
# -neopixel suffix from the basename so that both siblings map to the same canonical
# stem key (grove-led-driver). After sort -u on the id<TAB>canonical-stem pair, each
# shared id counts only once — not a collision. Ids shared across genuinely UNRELATED
# files still map to two distinct canonical stems and are correctly reported.
echo "=== Guard: no duplicate ids across packages/ ==="
# `-e` is active: a zero-match grep is a NORMAL passing condition, so `|| true`
# keeps the pipeline from aborting the run when there are no id lines at all.
DUPE_REPORT=$(
  grep -rEn --include="*.yaml" '^[[:space:]]*-?[[:space:]]*id:[[:space:]]*' packages/ 2>/dev/null \
  | sed -E "s|^([^:]+):[0-9]+:[[:space:]]*-?[[:space:]]*id:[[:space:]]*[\"']?([a-zA-Z_][a-zA-Z0-9_]*).*|\2\t\1|" \
  | awk -F'\t' 'NF == 2 { print }' \
  | sed -E 's/(-i2c|-neopixel)(\.yaml)$/\2/g' \
  | sort -u \
  | awk -F'\t' '{ count[$1]++; files[$1] = files[$1] " " $2 }
      END { for (id in count) if (count[id] > 1) print "DUPLICATE id=" id " in:" files[id] }' \
  || true
)
if [ -n "$DUPE_REPORT" ]; then
  echo "FAIL: Duplicate ids detected:"
  echo "$DUPE_REPORT"
  exit 1
fi
echo "OK — no duplicate ids across package files"

# Pass 1: esphome config
echo "=== esphome config ==="
for f in examples/*.yaml; do
  [[ "$(basename "$f")" == "secrets.yaml" ]] && continue
  echo "--- $f"
  if ./esphome.sh config "$f"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILURES+=("$f")
  fi
done

echo ""
echo "Config Check Results: $PASS passed, $FAIL failed"
if [ ${#FAILURES[@]} -gt 0 ]; then
  echo "Failed:"
  for f in "${FAILURES[@]}"; do echo "  $f"; done
  exit 1
fi

# Pass 2: esphome compile
echo "=== esphome compile ==="
for f in examples/*.yaml; do
  [[ "$(basename "$f")" == "secrets.yaml" ]] && continue
  echo "--- $f"
  if ./esphome.sh compile "$f"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILURES+=("$f")
  fi
done

echo ""
echo "Full Results: $PASS passed, $FAIL failed"
if [ ${#FAILURES[@]} -gt 0 ]; then
  echo "Failed:"
  for f in "${FAILURES[@]}"; do echo "  $f"; done
  exit 1
fi
