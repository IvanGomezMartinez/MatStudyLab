#!/usr/bin/env bash
# Pass/fail coverage for scripts/check-vendor-release.sh (controlled timestamps).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0

assert_eq() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $label — expected '$expected', got '$actual'" >&2
    failures=$((failures + 1))
  fi
}

assert_contains() {
  local label="$1"
  local needle="$2"
  local haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "FAIL: $label — output missing '$needle'" >&2
    echo "$haystack" >&2
    failures=$((failures + 1))
  fi
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Fresh within 24h → pass
pref_fresh="$tmpdir/pref-fresh.json"
python3 - "$pref_fresh" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

write_pref(Path(sys.argv[1]), {"mode": "auto", "last_synced_at": "2026-07-10T10:00:00.000Z"})
PY

set +e
fresh_out="$(
  BOOTSTRAP_PREF="$pref_fresh" \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/check-vendor-release.sh 2>&1
)"
fresh_status=$?
set -e
assert_eq "fresh release check exits 0" "0" "$fresh_status"
assert_contains "fresh release check OK" "vendor-release: OK" "$fresh_out"

# Stale >24h → fail
pref_stale="$tmpdir/pref-stale.json"
python3 - "$pref_stale" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

write_pref(Path(sys.argv[1]), {"mode": "auto", "last_synced_at": "2026-07-08T10:00:00.000Z"})
PY

set +e
stale_out="$(
  BOOTSTRAP_PREF="$pref_stale" \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/check-vendor-release.sh 2>&1
)"
stale_status=$?
set -e
assert_eq "stale release check exits 1" "1" "$stale_status"
assert_contains "stale release check FAIL" "vendor-release: FAIL" "$stale_out"

# Missing last_synced_at → fail
pref_null="$tmpdir/pref-null.json"
python3 - "$pref_null" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

write_pref(Path(sys.argv[1]), {"mode": "auto", "last_synced_at": None})
PY

set +e
null_out="$(
  BOOTSTRAP_PREF="$pref_null" \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/check-vendor-release.sh 2>&1
)"
null_status=$?
set -e
assert_eq "null last_synced_at exits 1" "1" "$null_status"
assert_contains "null last_synced_at FAIL" "vendor-release: FAIL" "$null_out"

# Missing pref file → fail
missing_pref="$tmpdir/does-not-exist.json"
set +e
missing_out="$(
  BOOTSTRAP_PREF="$missing_pref" \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/check-vendor-release.sh 2>&1
)"
missing_status=$?
set -e
assert_eq "missing pref exits 1" "1" "$missing_status"
assert_contains "missing pref FAIL" "vendor-release: FAIL" "$missing_out"

if [[ "$failures" -gt 0 ]]; then
  echo "vendor-release tests: $failures failure(s)" >&2
  exit 1
fi

echo "vendor-release tests: OK"
