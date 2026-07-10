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
  mkdir -p "$case_dir"/{codes,modify}/mtf/sample
  python3 - "$case_dir" "$mode" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from modify_bundle import catalog_bundle_unchanged, copy_catalog_to_modify

root = Path(sys.argv[1])
mode = sys.argv[2]
catalog = root / "codes/mtf/sample"
catalog.mkdir(parents=True, exist_ok=True)
(catalog / "through_focus_mtf.m").write_text("original", encoding="utf-8")
(catalog / "through_focus_mtf.md").write_text("base", encoding="utf-8")

if mode == "copy-mirror":
    dest = copy_catalog_to_modify(root, "mtf", "sample")
    print(dest.relative_to(root))
elif mode == "codes-unchanged":
    snapshot = {
        path.name: path.read_text(encoding="utf-8")
        for path in catalog.iterdir()
        if path.is_file()
    }
    copy_catalog_to_modify(root, "mtf", "sample")
    modify_file = root / "modify/mtf/sample/through_focus_mtf.m"
    modify_file.write_text("edited", encoding="utf-8")
    print("unchanged" if catalog_bundle_unchanged(root, "mtf", "sample", snapshot) else "changed")
elif mode == "resume-without-overwrite":
    first = copy_catalog_to_modify(root, "mtf", "sample")
    second = copy_catalog_to_modify(root, "mtf", "sample")
    print("same" if first == second else "different")
PY
}

assert_eq "copy to modify mirror path" "modify/mtf/sample" "$(run_case copy-mirror)"
assert_eq "codes stays unchanged after modify edit" "unchanged" "$(run_case codes-unchanged)"
assert_eq "resume copy without overwrite" "same" "$(run_case resume-without-overwrite)"

if [[ "$failures" -gt 0 ]]; then
  echo "modify-bundle tests: $failures failure(s)" >&2
  exit 1
fi

echo "modify-bundle tests: OK"
