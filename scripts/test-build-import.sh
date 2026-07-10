#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

assert_eq() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $label — expected '$expected', got '$actual'" >&2
    failures=$((failures + 1))
  fi
}

run_case() {
  local mode="$1"
  local case_dir
  case_dir="$(mktemp -d "$tmpdir/case.XXXXXX")"
  mkdir -p "$case_dir/import" "$case_dir/codes/mtf"
  python3 - "$case_dir" "$mode" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from build_import import (
    HomonymError,
    catalog_from_import,
    homonym_exists,
    propose_bundles,
    scan_import_matlab_files,
)

root = Path(sys.argv[1])
mode = sys.argv[2]

if mode == "scan-count":
    (root / "import/a/one.m").parent.mkdir(parents=True, exist_ok=True)
    (root / "import/a/one.m").write_text("x", encoding="utf-8")
    (root / "import/b/two.m").parent.mkdir(parents=True, exist_ok=True)
    (root / "import/b/two.m").write_text("x", encoding="utf-8")
    print(len(scan_import_matlab_files(root)))
elif mode == "proposal-name":
    (root / "import/mtf/through_focus").mkdir(parents=True)
    (root / "import/mtf/through_focus/through_focus_mtf.m").write_text("x", encoding="utf-8")
    proposals = propose_bundles(root)
    print(proposals[0].bundle_name)
elif mode == "catalog-move":
    source = root / "import/mtf/through_focus"
    source.mkdir(parents=True)
    (source / "through_focus_mtf.m").write_text("x", encoding="utf-8")
    (source / "data.csv").write_text("1", encoding="utf-8")
    result = catalog_from_import(root, "mtf", "through_focus_mtf", source)
    print("catalog" if (root / "codes/mtf/through_focus_mtf/through_focus_mtf.m").is_file() else "missing")
    print("import-cleared" if not source.exists() else "import-left")
    print("draft" if (root / "codes/mtf/through_focus_mtf/through_focus_mtf.md").is_file() else "no-draft")
elif mode == "homonym-block":
    (root / "codes/mtf/existing").mkdir(parents=True)
    (root / "codes/mtf/existing/existing.m").write_text("x", encoding="utf-8")
    source = root / "import/mtf/existing"
    source.mkdir(parents=True)
    (source / "existing.m").write_text("y", encoding="utf-8")
    try:
        catalog_from_import(root, "mtf", "existing", source)
        print("allowed")
    except HomonymError:
        print("blocked")
elif mode == "incremental":
  left = root / "import/left/left.m"
  right = root / "import/right/right.m"
  left.parent.mkdir(parents=True)
  right.parent.mkdir(parents=True)
  left.write_text("x", encoding="utf-8")
  right.write_text("x", encoding="utf-8")
  catalog_from_import(root, "mtf", "left", left.parent)
  print("right-remains" if right.is_file() else "right-gone")
PY
}

assert_eq "recursive scan" "2" "$(run_case scan-count)"
assert_eq "bundle name from folder" "through_focus" "$(run_case proposal-name)"
catalog_result="$(run_case catalog-move)"
assert_eq "catalog creates codes bundle" "catalog" "$(echo "$catalog_result" | sed -n '1p')"
assert_eq "import folder cleared" "import-cleared" "$(echo "$catalog_result" | sed -n '2p')"
assert_eq "draft companion created" "draft" "$(echo "$catalog_result" | sed -n '3p')"
assert_eq "homonym blocks catalog" "blocked" "$(run_case homonym-block)"
assert_eq "incremental import cleanup" "right-remains" "$(run_case incremental)"

if [[ "$failures" -gt 0 ]]; then
  echo "build-import tests: $failures failure(s)" >&2
  exit 1
fi

echo "build-import tests: OK"
