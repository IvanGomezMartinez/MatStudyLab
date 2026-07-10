#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BANK="$ROOT/codigosRealesNoSubir"
if [[ ! -d "$BANK" ]]; then
  echo "e2e-real-bank: SKIPPED (no codigosRealesNoSubir/)"
  exit 0
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

for area in import new modify explain codes; do
  mkdir -p "$tmpdir/$area"
done
for type in mtf psf fourier-transform strehl-ratio iol-profiles zernikes moire; do
  mkdir -p "$tmpdir/codes/$type"
  touch "$tmpdir/codes/$type/.gitkeep"
done
touch "$tmpdir/codes/.gitkeep"
cp -r "$ROOT/scripts" "$tmpdir/scripts"

python3 - "$tmpdir" "$BANK" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "scripts/lib"))
from e2e_real_bank import run_real_bank_build

catalog_dir = run_real_bank_build(Path(sys.argv[1]), Path(sys.argv[2]))
print(f"e2e-real-bank: catalog={catalog_dir}")
PY

echo "e2e-real-bank tests: OK"
