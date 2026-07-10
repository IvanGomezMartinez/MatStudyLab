#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0

assert_exists() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "FAIL: missing $path" >&2
    failures=$((failures + 1))
  fi
}

assert_readable() {
  local path="$1"
  if [[ ! -r "$path" ]]; then
    echo "FAIL: not readable $path" >&2
    failures=$((failures + 1))
  fi
}

seed_types=(
  mtf
  psf
  fourier-transform
  strehl-ratio
  iol-profiles
  zernikes
  moire
)

for folder in import new modify explain; do
  assert_exists "$folder/.gitkeep"
done

for type in "${seed_types[@]}"; do
  assert_exists "codes/$type/.gitkeep"
done

while IFS= read -r -d '' matlab_file; do
  echo "FAIL: proprietary .m found in catalog: $matlab_file" >&2
  failures=$((failures + 1))
done < <(find codes -name '*.m' -print0 2>/dev/null || true)

for doc in docs/spec.md CONTEXT.md docs/templates/LORE.md docs/templates/script-companion.md; do
  assert_exists "$doc"
  assert_readable "$doc"
done

if [[ "$failures" -gt 0 ]]; then
  echo "Template smoke: $failures failure(s)" >&2
  exit 1
fi

echo "Template smoke: OK"
