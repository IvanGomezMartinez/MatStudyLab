#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LOCKFILE="${BOOTSTRAP_LOCKFILE:-$ROOT/skills-lock.json}"
PREF_FILE="${BOOTSTRAP_PREF:-$ROOT/.matstudylab/skills-pref.json}"
DRY_RUN="${BOOTSTRAP_DRY_RUN:-0}"
NOW_ISO="${BOOTSTRAP_NOW_ISO:-}"

if [[ ! -f "$LOCKFILE" ]]; then
  echo "bootstrap: FAIL missing lockfile $LOCKFILE" >&2
  exit 1
fi

staleness="$(python3 - "$PREF_FILE" "$NOW_ISO" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path("scripts/lib")))
from skills_bootstrap import is_stale, load_pref

pref_path = Path(sys.argv[1])
now_iso = sys.argv[2]
now = (
    datetime.fromisoformat(now_iso.replace("Z", "+00:00"))
    if now_iso
    else datetime.now(timezone.utc)
)
pref = load_pref(pref_path)
print("stale" if is_stale(pref.get("last_synced_at"), now) else "fresh")
PY
)"

if [[ "$staleness" == "stale" ]]; then
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "bootstrap: WOULD_SYNC"
  elif npx skills@latest update -p -y; then
    echo "bootstrap: SYNC_OK"
  else
    echo "bootstrap: SYNC_FAILED_CONTINUE (using vendored skills in .agents/skills/)" >&2
  fi
else
  echo "bootstrap: SKIPPED_FRESH"
fi

python3 - "$PREF_FILE" "$NOW_ISO" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path("scripts/lib")))
from skills_bootstrap import touch_last_synced_at

pref_path = Path(sys.argv[1])
now_iso = sys.argv[2]
now = (
    datetime.fromisoformat(now_iso.replace("Z", "+00:00"))
    if now_iso
    else datetime.now(timezone.utc)
)
touch_last_synced_at(pref_path, now)
PY

echo "bootstrap: OK"
