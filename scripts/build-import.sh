#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ACTION="${1:-scan}"
TYPE="${2:-}"
BUNDLE="${3:-}"
SOURCE="${4:-}"
DRY_RUN="${BUILD_DRY_RUN:-0}"

python3 - "$ROOT" "$ACTION" "$TYPE" "$BUNDLE" "$SOURCE" "$DRY_RUN" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "scripts/lib"))
from build_import import (
    HomonymError,
    catalog_from_import,
    homonym_exists,
    propose_bundles,
    scan_import_matlab_files,
)

root = Path(sys.argv[1])
action = sys.argv[2]
type_name = sys.argv[3]
bundle_name = sys.argv[4]
source = sys.argv[5]
dry_run = sys.argv[6] == "1"

if action == "scan":
    for proposal in propose_bundles(root):
        rel_dir = proposal.source_dir.relative_to(root)
        files = ", ".join(path.name for path in proposal.matlab_files)
        print(f"build: {rel_dir} -> bundle '{proposal.bundle_name}' [{files}]")
    raise SystemExit(0)

if action == "homonym":
    exists = homonym_exists(root, type_name, bundle_name)
    print("homonym" if exists else "available")
    raise SystemExit(0)

if action == "catalog":
    source_dir = Path(source)
    if not source_dir.is_absolute():
        source_dir = root / source_dir
    try:
        result = catalog_from_import(
            root,
            type_name,
            bundle_name,
            source_dir,
            dry_run=dry_run,
        )
    except HomonymError as error:
        print(f"build: blocked — {error}", file=sys.stderr)
        raise SystemExit(2)
    rel_dest = result.catalog_dir.relative_to(root)
    print(f"build: cataloged -> {rel_dest}")
    for moved in result.moved_files:
        print(f"build: moved {moved.relative_to(root)}")
    if result.drafted_companion:
        print(f"build: drafted {result.drafted_companion.relative_to(root)}")
    raise SystemExit(0)

print("Usage: build-import.sh [scan|homonym|catalog] ...", file=sys.stderr)
raise SystemExit(1)
PY
