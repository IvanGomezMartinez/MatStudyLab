#!/usr/bin/env bash
# Release freshness (maintainer A+C ritual — C half).
# Run AFTER orchestrator setup/update (A) and BEFORE tagging a release.
# Fails when .matstudylab/skills-pref.json is missing last_synced_at or it is older
# than 24h (skills_bootstrap.is_stale). Not part of default daily ./scripts/qa.sh.
# Env: BOOTSTRAP_PREF (pref path), BOOTSTRAP_NOW_ISO (fixed "now" for tests).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PREF_FILE="${BOOTSTRAP_PREF:-$ROOT/.matstudylab/skills-pref.json}"
NOW_ISO="${BOOTSTRAP_NOW_ISO:-}"

python3 - "$PREF_FILE" "$NOW_ISO" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path("scripts/lib")))
from skills_bootstrap import release_freshness_ok

pref_path = Path(sys.argv[1])
now_iso = sys.argv[2]
now = (
    datetime.fromisoformat(now_iso.replace("Z", "+00:00"))
    if now_iso
    else datetime.now(timezone.utc)
)
ok, message = release_freshness_ok(pref_path, now)
if not ok:
    print(f"vendor-release: FAIL {message}", file=sys.stderr)
    raise SystemExit(1)
print(f"vendor-release: OK {message}")
PY
