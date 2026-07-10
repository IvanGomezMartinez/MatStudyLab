#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "MatStudyLab QA — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

run() {
  echo "▶ $*"
  "$@"
}

run ./scripts/template-smoke.sh
run ./scripts/test-bootstrap-skills.sh
run ./scripts/test-accept-bundle.sh
run ./scripts/test-explain-bundle.sh
run ./scripts/test-build-import.sh
run ./scripts/test-new-bundle.sh
run ./scripts/test-modify-bundle.sh
run ./scripts/test-e2e-pipeline.sh

required_skills=(
  matstudylab-bootstrap
  accept
  explain
  build
  new
  modify
  matlab
  matlab-performance-optimizer
)

for skill in "${required_skills[@]}"; do
  path=".agents/skills/${skill}/SKILL.md"
  if [[ ! -f "$path" ]]; then
    echo "FAIL: missing $path" >&2
    exit 1
  fi
done
echo "▶ project skills present: OK"

if find codes -name '*.m' -print -quit 2>/dev/null | grep -q .; then
  echo "FAIL: proprietary .m found under codes/" >&2
  exit 1
fi
echo "▶ codes/ catalog empty: OK"

if [[ -d codigosRealesNoSubir ]] && git check-ignore -q codigosRealesNoSubir/; then
  echo "▶ codigosRealesNoSubir/ gitignored: OK"
else
  echo "WARN: codigosRealesNoSubir/ missing or not gitignored (local E2E bank optional)"
fi

echo ""
echo "QA: PASS"
