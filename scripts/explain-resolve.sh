#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ACTION="${1:-list}"
HINT="${2:-}"
QUESTION="${3:-}"

python3 - "$ROOT" "$ACTION" "$HINT" "$QUESTION" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "scripts/lib"))
from explain_bundle import (
    list_scripts_under_explain,
    resolve_script,
    scaffold_explain_doc,
)

root = Path(sys.argv[1])
action = sys.argv[2]
hint = sys.argv[3] or None
question = sys.argv[4] or None

if action == "list":
    for script in list_scripts_under_explain(root):
        print(script.relative_to(root))
    raise SystemExit(0)

if action == "resolve":
    target = resolve_script(root, hint)
    print(target.script_path.relative_to(root))
    print(target.output_path.relative_to(root))
    if target.catalog_path:
        print(target.catalog_path.relative_to(root))
    raise SystemExit(0)

if action == "scaffold":
    target = resolve_script(root, hint)
    path = scaffold_explain_doc(root, target, user_question=question)
    print(path.relative_to(root))
    raise SystemExit(0)

print("Usage: explain-resolve.sh [list|resolve|scaffold] [hint] [question]", file=sys.stderr)
raise SystemExit(1)
PY
