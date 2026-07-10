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

run ./scripts/validate-command-skills.sh
run ./scripts/test-bootstrap-skills.sh
run ./scripts/test-accept-bundle.sh
run ./scripts/test-explain-bundle.sh
run ./scripts/test-build-import.sh
run ./scripts/test-new-bundle.sh
run ./scripts/test-modify-bundle.sh
run ./scripts/test-e2e-pipeline.sh

echo ""
echo "QA: PASS"
