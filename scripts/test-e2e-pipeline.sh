#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

prepare_workspace() {
  for area in import new modify explain codes; do
    mkdir -p "$tmpdir/$area"
  done
  for type in mtf psf fourier-transform strehl-ratio iol-profiles zernikes moire; do
    mkdir -p "$tmpdir/codes/$type"
    touch "$tmpdir/codes/$type/.gitkeep"
  done
  touch "$tmpdir/codes/.gitkeep"
  cp -r "$ROOT/scripts" "$tmpdir/scripts"
}

run_e2e() {
  python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "scripts/lib"))
from e2e_pipeline import assert_import_fixture_removed, run_pipeline

root = Path(sys.argv[1])
result = run_pipeline(root)
assert_import_fixture_removed(root)

print(f"e2e: catalog={result.catalog_dir.name}")
print(f"e2e: explain={result.explain_doc.name}")
print(f"e2e: attached={result.accepted_explain.name}")
PY
}

prepare_workspace
if ! output="$(run_e2e 2>&1)"; then
  echo "FAIL: E2E pipeline run" >&2
  echo "$output" >&2
  failures=$((failures + 1))
else
  echo "$output"
  echo "$output" | grep -q "e2e: catalog=synthetic_iol_profile" || failures=$((failures + 1))
  echo "$output" | grep -q "e2e: explain=explain_synthetic_iol_profile.md" || failures=$((failures + 1))
  echo "$output" | grep -q "e2e: attached=explain_synthetic_iol_profile.md" || failures=$((failures + 1))
fi

if [[ "$failures" -gt 0 ]]; then
  echo "e2e-pipeline tests: $failures failure(s)" >&2
  exit 1
fi

echo "e2e-pipeline tests: OK"
