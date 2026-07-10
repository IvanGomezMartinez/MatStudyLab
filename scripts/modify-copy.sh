#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TYPE="${1:-}"
BUNDLE="${2:-}"
OVERWRITE="${MODIFY_OVERWRITE:-0}"
DRY_RUN="${MODIFY_DRY_RUN:-0}"

if [[ -z "$TYPE" || -z "$BUNDLE" ]]; then
  echo "Usage: $0 <type> <bundle>" >&2
  exit 1
fi

python3 - "$ROOT" "$TYPE" "$BUNDLE" "$OVERWRITE" "$DRY_RUN" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "scripts/lib"))
from modify_bundle import copy_catalog_to_modify

root = Path(sys.argv[1])
type_name = sys.argv[2]
bundle_name = sys.argv[3]
overwrite = sys.argv[4] == "1"
dry_run = sys.argv[5] == "1"

destination = copy_catalog_to_modify(
    root,
    type_name,
    bundle_name,
    overwrite=overwrite,
    dry_run=dry_run,
)
print(destination.relative_to(root))
PY
