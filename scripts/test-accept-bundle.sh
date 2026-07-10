#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0

run_python() {
  python3 - "$@" <<'PY'
import shutil
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from accept_bundle import (
    BundleRef,
    accept_bundle,
    accept_explain_attachments,
    list_pending_bundles,
    validate_bundle,
)

root = Path(sys.argv[1])
mode = sys.argv[2]

if mode == "pending-count":
    print(len(list_pending_bundles(root)))
elif mode == "validate-ok":
    result = validate_bundle(root / "new/mtf/sample_bundle")
    raise SystemExit(0 if result.ok else 1)
elif mode == "validate-missing-md":
    result = validate_bundle(root / "new/mtf/sample_bundle")
    print("ok" if result.ok else "fail")
elif mode == "accept-new":
    bundle = BundleRef("new", "mtf", "sample_bundle")
    attached = accept_bundle(root, bundle)
    print(len(attached))
elif mode == "accept-modify":
    shutil.copytree(
        root / "new/mtf/sample_bundle",
        root / "modify/mtf/sample_bundle",
        dirs_exist_ok=True,
    )
    (root / "codes/mtf/sample_bundle").mkdir(parents=True, exist_ok=True)
    (root / "codes/mtf/sample_bundle/old.m").write_text("x", encoding="utf-8")
    bundle = BundleRef("modify", "mtf", "sample_bundle")
    accept_bundle(root, bundle)
    print(
        "replaced"
        if not (root / "codes/mtf/sample_bundle/old.m").exists()
        else "not-replaced"
    )
elif mode == "accept-explain":
    (root / "codes/mtf/sample_bundle").mkdir(parents=True, exist_ok=True)
    shutil.copy2(
        root / "new/mtf/sample_bundle/through_focus_mtf.m",
        root / "codes/mtf/sample_bundle/through_focus_mtf.m",
    )
    (root / "explain/mtf/sample_bundle").mkdir(parents=True, exist_ok=True)
    (root / "explain/mtf/sample_bundle/explain_through_focus_mtf.md").write_text(
        "# Deep study", encoding="utf-8"
    )
    attached = accept_explain_attachments(
        root, type_name="mtf", bundle_name="sample_bundle"
    )
    print(len(attached))
PY
}

make_fixture() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"/{new,modify,codes,explain}/mtf
  mkdir -p "$dir/new/mtf/sample_bundle"
  cat >"$dir/new/mtf/sample_bundle/through_focus_mtf.m" <<'EOF'
%% Parameters
EOF
  cat >"$dir/new/mtf/sample_bundle/through_focus_mtf.md" <<'EOF'
# Through-focus MTF
EOF
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

make_fixture "$tmpdir"
assert_eq() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $label — expected '$expected', got '$actual'" >&2
    failures=$((failures + 1))
  fi
}

pending_count="$(run_python "$tmpdir" pending-count)"
assert_eq "pending bundle count" "1" "$pending_count"

if ! run_python "$tmpdir" validate-ok; then
  echo "FAIL: valid bundle should pass validation" >&2
  failures=$((failures + 1))
fi

rm -f "$tmpdir/new/mtf/sample_bundle/through_focus_mtf.md"
missing_md="$(run_python "$tmpdir" validate-missing-md)"
assert_eq "block without .md" "fail" "$missing_md"

make_fixture "$tmpdir"
cat >"$tmpdir/explain/explain_through_focus_mtf.md" <<'EOF'
# Deep study
EOF
attached_count="$(run_python "$tmpdir" accept-new)"
assert_eq "explain attachment count" "1" "$attached_count"
if [[ ! -f "$tmpdir/codes/mtf/sample_bundle/through_focus_mtf.m" ]]; then
  echo "FAIL: catalog .m missing after accept" >&2
  failures=$((failures + 1))
fi
if [[ ! -f "$tmpdir/codes/mtf/sample_bundle/explain_through_focus_mtf.md" ]]; then
  echo "FAIL: explain doc missing after accept" >&2
  failures=$((failures + 1))
fi
if [[ -f "$tmpdir/explain/explain_through_focus_mtf.md" ]]; then
  echo "FAIL: explain source still present after accept new" >&2
  failures=$((failures + 1))
fi
if [[ -d "$tmpdir/new/mtf/sample_bundle" ]]; then
  echo "FAIL: staging not cleared after accept" >&2
  failures=$((failures + 1))
fi

make_fixture "$tmpdir"
replace_result="$(run_python "$tmpdir" accept-modify)"
assert_eq "modify replaces catalog bundle" "replaced" "$replace_result"

make_fixture "$tmpdir"
explain_only_count="$(run_python "$tmpdir" accept-explain)"
assert_eq "accept explain attachment count" "1" "$explain_only_count"
if [[ ! -f "$tmpdir/codes/mtf/sample_bundle/explain_through_focus_mtf.md" ]]; then
  echo "FAIL: explain doc missing after accept explain" >&2
  failures=$((failures + 1))
fi
if [[ -f "$tmpdir/explain/mtf/sample_bundle/explain_through_focus_mtf.md" ]]; then
  echo "FAIL: explain source still present after accept explain" >&2
  failures=$((failures + 1))
fi
if [[ ! -d "$tmpdir/new/mtf/sample_bundle" ]]; then
  echo "FAIL: new staging cleared unexpectedly after accept explain" >&2
  failures=$((failures + 1))
fi

if [[ "$failures" -gt 0 ]]; then
  echo "accept-bundle tests: $failures failure(s)" >&2
  exit 1
fi

echo "accept-bundle tests: OK"
