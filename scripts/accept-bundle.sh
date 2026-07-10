#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VARIANT="${1:-all}"
TYPE="${2:-}"
BUNDLE="${3:-}"
DRY_RUN="${ACCEPT_DRY_RUN:-0}"

usage() {
  echo "Usage: $0 [all|new|modify] [type bundle]" >&2
  exit 1
}

case "$VARIANT" in
  all | new | modify) ;;
  *) usage ;;
esac

if [[ -n "$TYPE" && -z "$BUNDLE" ]] || [[ -z "$TYPE" && -n "$BUNDLE" ]]; then
  usage
fi

python3 - "$ROOT" "$VARIANT" "$TYPE" "$BUNDLE" "$DRY_RUN" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "scripts/lib"))
from accept_bundle import BundleRef, accept_bundle, list_pending_bundles

root = Path(sys.argv[1])
variant = sys.argv[2]
type_name = sys.argv[3]
bundle_name = sys.argv[4]
dry_run = sys.argv[5] == "1"

pending = list_pending_bundles(root)
if type_name and bundle_name:
    pending = [
        bundle
        for bundle in pending
        if bundle.type_name == type_name and bundle.bundle_name == bundle_name
    ]

if variant == "new":
    pending = [bundle for bundle in pending if bundle.staging == "new"]
elif variant == "modify":
    pending = [bundle for bundle in pending if bundle.staging == "modify"]

if not pending:
    print("accept: no pending bundles")
    raise SystemExit(0)

for bundle in pending:
    attached = accept_bundle(root, bundle, dry_run=dry_run)
    print(
        f"accept: promoted {bundle.staging}/{bundle.type_name}/{bundle.bundle_name} "
        f"-> codes/{bundle.type_name}/{bundle.bundle_name}"
    )
    for path in attached:
        print(f"accept: attached {path.relative_to(root)}")
PY
