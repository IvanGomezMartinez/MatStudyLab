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

last_synced_at = sys.argv[1] if sys.argv[1] != "NONE" else None
now = datetime.fromisoformat(sys.argv[2].replace("Z", "+00:00"))
print("stale" if is_stale(last_synced_at, now) else "fresh")
PY
}

fresh_result="$(python_is_stale "2026-07-10T12:00:00.000Z" "2026-07-10T13:00:00.000Z")"
assert_eq "fresh last_synced_at within 24h" "fresh" "$fresh_result"

stale_result="$(python_is_stale "2026-07-09T10:00:00.000Z" "2026-07-10T13:00:00.000Z")"
assert_eq "stale last_synced_at after 24h" "stale" "$stale_result"

missing_result="$(python_is_stale "NONE" "2026-07-10T13:00:00.000Z")"
assert_eq "missing last_synced_at is stale" "stale" "$missing_result"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Missing preference file → auto + never synced (stale)
missing_pref="$tmpdir/missing-pref.json"
missing_pref_json="$(python3 - "$missing_pref" <<'PY'
import json
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import load_pref

pref = load_pref(Path(sys.argv[1]))
print(json.dumps({"mode": pref["mode"], "last_synced_at": pref["last_synced_at"]}))
PY
)"
assert_eq "missing pref defaults to auto/null" '{"mode": "auto", "last_synced_at": null}' "$missing_pref_json"

cp skills-lock.json "$tmpdir/skills-lock.json"
pref_fresh="$tmpdir/skills-pref-fresh.json"
python3 - "$pref_fresh" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import touch_last_synced_at

path = Path(sys.argv[1])
updated = touch_last_synced_at(path, datetime(2026, 7, 10, 14, 0, tzinfo=timezone.utc))
print(updated)
PY

# Capture lock last_checked before bootstrap so we prove we no longer write it
lock_before="$(python3 - "$tmpdir/skills-lock.json" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("last_checked", "ABSENT"))
PY
)"

fresh_output="$(
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$pref_fresh" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh
)"
assert_contains "fresh bootstrap skips sync" "bootstrap: SKIPPED_FRESH" "$fresh_output"
assert_contains "fresh bootstrap completes" "bootstrap: OK" "$fresh_output"

pref_after_fresh="$(python3 - "$pref_fresh" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["last_synced_at"])
PY
)"
assert_eq "SKIPPED_FRESH stamps last_synced_at" "2026-07-10T14:30:00.000Z" "$pref_after_fresh"

lock_after="$(python3 - "$tmpdir/skills-lock.json" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("last_checked", "ABSENT"))
PY
)"
assert_eq "bootstrap does not rewrite lock last_checked" "$lock_before" "$lock_after"

# Stale sidecar → WOULD_SYNC; lock last_checked must be ignored even if fresh-looking
cp skills-lock.json "$tmpdir/skills-lock-stale.json"
pref_stale="$tmpdir/skills-pref-stale.json"
python3 - "$pref_stale" "$tmpdir/skills-lock-stale.json" <<'PY'
import json
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

pref_path = Path(sys.argv[1])
lock_path = Path(sys.argv[2])
write_pref(pref_path, {"mode": "auto", "last_synced_at": "2026-07-08T10:00:00.000Z"})
# Poison the lock with a "fresh" last_checked — bootstrap must ignore it
data = json.loads(lock_path.read_text(encoding="utf-8"))
data["last_checked"] = "2026-07-10T14:00:00.000Z"
lock_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

stale_output="$(
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock-stale.json" \
  BOOTSTRAP_PREF="$pref_stale" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh
)"
assert_contains "stale bootstrap dry-run sync" "bootstrap: WOULD_SYNC" "$stale_output"
assert_contains "stale bootstrap completes" "bootstrap: OK" "$stale_output"

pref_after_stale="$(python3 - "$pref_stale" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["last_synced_at"])
PY
)"
assert_eq "WOULD_SYNC stamps last_synced_at" "2026-07-10T14:30:00.000Z" "$pref_after_stale"

# Missing pref file → stale (never synced)
missing_pref_path="$tmpdir/does-not-exist.json"
missing_output="$(
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$missing_pref_path" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh
)"
assert_contains "missing pref bootstrap dry-run sync" "bootstrap: WOULD_SYNC" "$missing_output"
assert_contains "missing pref bootstrap completes" "bootstrap: OK" "$missing_output"
assert_eq "missing pref creates sidecar on stamp" "true" "$(
  [[ -f "$missing_pref_path" ]] && echo true || echo false
)"

if [[ "$failures" -gt 0 ]]; then
  echo "bootstrap-skills tests: $failures failure(s)" >&2
  exit 1
fi

echo "bootstrap-skills tests: OK"
