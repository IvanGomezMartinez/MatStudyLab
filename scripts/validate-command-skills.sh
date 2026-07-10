#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(".")
WORKFLOW_SKILLS = ("accept", "explain", "build", "new", "modify")
BOOTSTRAP_SKILL = "matstudylab-bootstrap"

REQUIRED_MARKERS = (
    "disable-model-invocation: true",
    "## Step 0 — Bootstrap (mandatory)",
    "matstudylab-bootstrap/SKILL.md",
    "**Completion criterion:**",
    "## Safety (non-negotiable)",
)

failures: list[str] = []


def check_skill(skill_name: str, path: Path) -> None:
    if not path.is_file():
        failures.append(f"missing skill file: {path}")
        return

    text = path.read_text(encoding="utf-8")
    for marker in REQUIRED_MARKERS:
        if marker not in text:
            failures.append(f"{skill_name}: missing marker {marker!r}")

    steps = re.findall(r"^## Step \d+", text, flags=re.MULTILINE)
    criteria = text.count("**Completion criterion:**")
    if len(steps) < 2:
        failures.append(f"{skill_name}: expected at least 2 steps, found {len(steps)}")
    if criteria < len(steps):
        failures.append(
            f"{skill_name}: {criteria} completion criteria for {len(steps)} steps"
        )


for skill in WORKFLOW_SKILLS:
    check_skill(skill, ROOT / ".agents/skills" / skill / "SKILL.md")

bootstrap_path = ROOT / ".agents/skills" / BOOTSTRAP_SKILL / "SKILL.md"
if bootstrap_path.is_file():
    bootstrap_text = bootstrap_path.read_text(encoding="utf-8")
    if "disable-model-invocation: true" not in bootstrap_text:
        failures.append(f"{BOOTSTRAP_SKILL}: missing disable-model-invocation")
    if "**Completion criterion:**" not in bootstrap_text:
        failures.append(f"{BOOTSTRAP_SKILL}: missing completion criteria")
else:
    failures.append(f"missing bootstrap skill: {bootstrap_path}")

if failures:
    print("validate-command-skills: FAIL", file=sys.stderr)
    for item in failures:
        print(f"  - {item}", file=sys.stderr)
    raise SystemExit(1)

print("validate-command-skills: OK")
PY
