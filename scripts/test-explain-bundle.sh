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

run_python() {
  local mode="$1"
  local case_dir
  case_dir="$(mktemp -d "$tmpdir/case.XXXXXX")"
  python3 - "$case_dir" "$mode" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from explain_bundle import (
    explain_output_path,
    list_scripts_under_explain,
    resolve_script,
    scaffold_explain_doc,
    validate_explain_doc,
)

root = Path(sys.argv[1])
mode = sys.argv[2]

if mode == "codes-output":
    script = root / "codes/mtf/sample/through_focus_mtf.m"
    script.parent.mkdir(parents=True, exist_ok=True)
    script.write_text("x", encoding="utf-8")
    output = explain_output_path(root, script)
    print(output.relative_to(root))
elif mode == "explain-flat-output":
    script = root / "explain/demo.m"
    script.parent.mkdir(parents=True, exist_ok=True)
    script.write_text("x", encoding="utf-8")
    output = explain_output_path(root, script)
    print(output.relative_to(root))
elif mode == "list-count":
    (root / "explain/a.m").parent.mkdir(parents=True, exist_ok=True)
    (root / "explain/a.m").write_text("x", encoding="utf-8")
    print(len(list_scripts_under_explain(root)))
elif mode == "scaffold-valid":
    script = root / "explain/study.m"
    script.parent.mkdir(parents=True, exist_ok=True)
    script.write_text("x", encoding="utf-8")
    target = resolve_script(root, "explain/study.m")
    path = scaffold_explain_doc(root, target, user_question="Why FFT here?")
    print("valid" if validate_explain_doc(path) else "invalid")
elif mode == "block-outside-explain":
    from explain_bundle import ExplainTarget, assert_output_in_explain
    try:
        assert_output_in_explain(root, root / "codes/bad.md")
        print("allowed")
    except ValueError:
        print("blocked")
PY
}

assert_eq "codes script output path" "explain/mtf/sample/explain_through_focus_mtf.md" "$(run_python codes-output)"
assert_eq "flat explain script output path" "explain/explain_demo.md" "$(run_python explain-flat-output)"
assert_eq "list scripts under explain" "1" "$(run_python list-count)"
assert_eq "scaffold has required sections" "valid" "$(run_python scaffold-valid)"
assert_eq "block writes outside explain" "blocked" "$(run_python block-outside-explain)"

if [[ "$failures" -gt 0 ]]; then
  echo "explain-bundle tests: $failures failure(s)" >&2
  exit 1
fi

echo "explain-bundle tests: OK"
