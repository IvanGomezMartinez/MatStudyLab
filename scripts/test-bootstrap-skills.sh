#!/usr/bin/env bash
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

python_is_stale() {
  python3 - "$@" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path("scripts/lib")))
from skills_bootstrap import is_stale

last_checked = sys.argv[1] if sys.argv[1] != "NONE" else None
now = datetime.fromisoformat(sys.argv[2].replace("Z", "+00:00"))
print("stale" if is_stale(last_checked, now) else "fresh")
PY
}

fresh_result="$(python_is_stale "2026-07-10T12:00:00.000Z" "2026-07-10T13:00:00.000Z")"
assert_eq "fresh lockfile within 24h" "fresh" "$fresh_result"

stale_result="$(python_is_stale "2026-07-09T10:00:00.000Z" "2026-07-10T13:00:00.000Z")"
assert_eq "stale lockfile after 24h" "stale" "$stale_result"

missing_result="$(python_is_stale "NONE" "2026-07-10T13:00:00.000Z")"
assert_eq "missing last_checked is stale" "stale" "$missing_result"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cp skills-lock.json "$tmpdir/skills-lock.json"
python3 - "$tmpdir/skills-lock.json" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import touch_last_checked

path = Path(sys.argv[1])
updated = touch_last_checked(path, datetime(2026, 7, 10, 14, 0, tzinfo=timezone.utc))
print(updated)
PY

fresh_output="$(BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" BOOTSTRAP_DRY_RUN=1 BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" ./scripts/bootstrap-skills.sh)"
assert_contains "fresh bootstrap skips sync" "bootstrap: SKIPPED_FRESH" "$fresh_output"
assert_contains "fresh bootstrap completes" "bootstrap: OK" "$fresh_output"

cp skills-lock.json "$tmpdir/skills-lock-stale.json"
python3 - "$tmpdir/skills-lock-stale.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["last_checked"] = "2026-07-08T10:00:00.000Z"
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

stale_output="$(BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock-stale.json" BOOTSTRAP_DRY_RUN=1 BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" ./scripts/bootstrap-skills.sh)"
assert_contains "stale bootstrap dry-run sync" "bootstrap: WOULD_SYNC" "$stale_output"
assert_contains "stale bootstrap completes" "bootstrap: OK" "$stale_output"

if [[ "$failures" -gt 0 ]]; then
  echo "bootstrap-skills tests: $failures failure(s)" >&2
  exit 1
fi

echo "bootstrap-skills tests: OK"
