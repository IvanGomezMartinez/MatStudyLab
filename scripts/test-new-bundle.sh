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
  mkdir -p "$case_dir/new"
  python3 - "$case_dir" "$mode" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from new_bundle import NewBundleTarget, scaffold_new_bundle, validate_stem

root = Path(sys.argv[1])
mode = sys.argv[2]

if mode == "valid-stem":
    print("valid" if not validate_stem("through_focus_mtf") else "invalid")
elif mode == "verb-prefix":
    print("invalid" if validate_stem("compute_mtf") else "valid")
elif mode == "scaffold-paths":
    target = NewBundleTarget("mtf", "through_focus_mtf", "through_focus_mtf")
    script_path, companion_path = scaffold_new_bundle(root, target)
    print(script_path.relative_to(root))
    print(companion_path.relative_to(root))
elif mode == "block-outside-new":
    from new_bundle import assert_writes_only_new
    target = NewBundleTarget("../codes", "hack", "hack")
    try:
        assert_writes_only_new(root, target)
        print("allowed")
    except ValueError:
        print("blocked")
PY
}

assert_eq "valid snake_case stem" "valid" "$(run_case valid-stem)"
assert_eq "reject verb prefix" "invalid" "$(run_case verb-prefix)"
paths="$(run_case scaffold-paths)"
assert_eq "script under new/type/bundle" "new/mtf/through_focus_mtf/through_focus_mtf.m" "$(echo "$paths" | sed -n '1p')"
assert_eq "companion under new/type/bundle" "new/mtf/through_focus_mtf/through_focus_mtf.md" "$(echo "$paths" | sed -n '2p')"
assert_eq "block writes outside new" "blocked" "$(run_case block-outside-new)"

if [[ "$failures" -gt 0 ]]; then
  echo "new-bundle tests: $failures failure(s)" >&2
  exit 1
fi

echo "new-bundle tests: OK"
