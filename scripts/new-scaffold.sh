#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ACTION="${1:-checklist}"
TYPE="${2:-}"
BUNDLE="${3:-}"
STEM="${4:-}"
DRY_RUN="${NEW_DRY_RUN:-0}"

python3 - "$ROOT" "$ACTION" "$TYPE" "$BUNDLE" "$STEM" "$DRY_RUN" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "scripts/lib"))
from new_bundle import CHECKLIST_ITEMS, NewBundleTarget, scaffold_new_bundle, validate_stem

root = Path(sys.argv[1])
action = sys.argv[2]
type_name = sys.argv[3]
bundle_name = sys.argv[4]
stem = sys.argv[5]
dry_run = sys.argv[6] == "1"

if action == "checklist":
    for index, item in enumerate(CHECKLIST_ITEMS, start=1):
        print(f"new: checklist {index} — {item}")
    raise SystemExit(0)

if action == "validate":
    errors = validate_stem(stem)
    print("valid" if not errors else "invalid: " + "; ".join(errors))
    raise SystemExit(0 if not errors else 2)

if action == "scaffold":
    target = NewBundleTarget(type_name, bundle_name, stem)
    script_path, companion_path = scaffold_new_bundle(root, target, dry_run=dry_run)
    print(script_path.relative_to(root))
    print(companion_path.relative_to(root))
    raise SystemExit(0)

print("Usage: new-scaffold.sh [checklist|validate|scaffold] ...", file=sys.stderr)
raise SystemExit(1)
PY
