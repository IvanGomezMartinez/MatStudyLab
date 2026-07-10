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

assert_exists "codes/.gitkeep"

for type in "${seed_types[@]}"; do
  assert_exists "codes/$type/.gitkeep"
done

while IFS= read -r -d '' unexpected; do
  echo "FAIL: codes/ must contain only .gitkeep placeholders: $unexpected" >&2
  failures=$((failures + 1))
done < <(find codes -type f ! -name '.gitkeep' -print0 2>/dev/null || true)

for doc in docs/spec.md CONTEXT.md README.md AGENTS.md docs/templates/LORE.md docs/templates/script-companion.md; do
  assert_exists "$doc"
  assert_readable "$doc"
done

if ! grep -q 'docs/templates/LORE.md' README.md; then
  echo "FAIL: README must instruct copying docs/templates/LORE.md to LORE.md" >&2
  failures=$((failures + 1))
fi

assert_exists ".agents/skills/matstudylab-bootstrap/SKILL.md"
assert_exists ".agents/skills/accept/SKILL.md"
assert_exists ".agents/skills/explain/SKILL.md"
assert_exists "scripts/bootstrap-skills.sh"
assert_exists "scripts/accept-bundle.sh"
assert_exists "scripts/explain-resolve.sh"
assert_exists "docs/templates/explain-doc.md"
assert_exists "docs/agents/command-skill-step-0.md"

if ! ./scripts/test-bootstrap-skills.sh >/dev/null; then
  echo "FAIL: bootstrap-skills tests" >&2
  failures=$((failures + 1))
fi

if ! ./scripts/test-accept-bundle.sh >/dev/null; then
  echo "FAIL: accept-bundle tests" >&2
  failures=$((failures + 1))
fi

if ! ./scripts/test-explain-bundle.sh >/dev/null; then
  echo "FAIL: explain-bundle tests" >&2
  failures=$((failures + 1))
fi

if [[ "$failures" -gt 0 ]]; then
  echo "Template smoke: $failures failure(s)" >&2
  exit 1
fi

echo "Template smoke: OK"
