#!/usr/bin/env bash
# Daily QA: local vendor integrity only (no upstream network / registry calls).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LOCKFILE="${BOOTSTRAP_LOCKFILE:-$ROOT/skills-lock.json}"
PREF_FILE="${BOOTSTRAP_PREF:-$ROOT/.matstudylab/skills-pref.json}"

python3 - "$ROOT" "$LOCKFILE" "$PREF_FILE" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path("scripts/lib")))
from skills_bootstrap import check_local_integrity

repo_root = Path(sys.argv[1])
lock_path = Path(sys.argv[2])
pref_path = Path(sys.argv[3])
failures = check_local_integrity(repo_root, lock_path=lock_path, pref_path=pref_path)
if failures:
    print("skills-integrity: FAIL", file=sys.stderr)
    for item in failures:
        print(f"  - {item}", file=sys.stderr)
    raise SystemExit(1)
print("skills-integrity: OK")
PY
