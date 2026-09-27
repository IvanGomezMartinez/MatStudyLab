#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LOCKFILE="${BOOTSTRAP_LOCKFILE:-$ROOT/skills-lock.json}"
PREF_FILE="${BOOTSTRAP_PREF:-$ROOT/.matstudylab/skills-pref.json}"
DRY_RUN="${BOOTSTRAP_DRY_RUN:-0}"
NOW_ISO="${BOOTSTRAP_NOW_ISO:-}"
FORCE_NO_NODE="${BOOTSTRAP_FORCE_NO_NODE:-0}"
PLANNED_SKILLS="${BOOTSTRAP_PLANNED_SKILLS:-}"

if [[ ! -f "$LOCKFILE" ]]; then
  echo "bootstrap: FAIL missing lockfile $LOCKFILE" >&2
  exit 1
fi

decision="$(
  BOOTSTRAP_FORCE_NO_NODE="$FORCE_NO_NODE" \
  BOOTSTRAP_PLANNED_SKILLS="$PLANNED_SKILLS" \
  python3 - "$LOCKFILE" "$PREF_FILE" "$NOW_ISO" <<'PY'
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path("scripts/lib")))
from skills_bootstrap import (
    decide_sync_action,
    load_lockfile,
    load_pref,
    name_guard_collisions,
    node_available,
    owned_skills_in_lock,
)

lock_path = Path(sys.argv[1])
pref_path = Path(sys.argv[2])
now_iso = sys.argv[3]
now = (
    datetime.fromisoformat(now_iso.replace("Z", "+00:00"))
    if now_iso
    else datetime.now(timezone.utc)
)
lock = load_lockfile(lock_path)
pref = load_pref(pref_path)
action = decide_sync_action(lock, pref, now)

if action == "local-only":
    print("action=local-only")
    sys.exit(0)

if action == "fresh":
    print("action=fresh")
    sys.exit(0)

force_no_node = os.environ.get("BOOTSTRAP_FORCE_NO_NODE", "0") == "1"
if not node_available(force_no_node=force_no_node):
    print("action=node-missing")
    sys.exit(0)

owned_in_lock = owned_skills_in_lock(lock)
if owned_in_lock:
    print("action=name-guard-fail")
    print("collisions=" + ",".join(owned_in_lock))
    sys.exit(0)

planned_raw = os.environ.get("BOOTSTRAP_PLANNED_SKILLS", "").strip()
if planned_raw:
    planned = [part.strip() for part in planned_raw.split(",") if part.strip()]
    collisions = name_guard_collisions(planned)
    if collisions:
        print("action=name-guard-fail")
        print("collisions=" + ",".join(collisions))
        sys.exit(0)

print(f"action={action}")
PY
)"

action="$(printf '%s\n' "$decision" | awk -F= '/^action=/{print $2; exit}')"
collisions="$(printf '%s\n' "$decision" | awk -F= '/^collisions=/{print $2; exit}')"

stamp_pref() {
  # Only call after SETUP_OK / UPDATE_OK — never on SKIPPED_FRESH (would slide the 24h window).
  python3 - "$PREF_FILE" "$NOW_ISO" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path("scripts/lib")))
from skills_bootstrap import record_successful_sync

pref_path = Path(sys.argv[1])
now_iso = sys.argv[2]
now = (
    datetime.fromisoformat(now_iso.replace("Z", "+00:00"))
    if now_iso
    else datetime.now(timezone.utc)
)
record_successful_sync(pref_path, now)
PY
}

run_setup() {
  npx skills@latest add mattpocock/skills --skill '*' -a cursor -y --copy \
    && gh skill install K-Dense-AI/scientific-agent-skills skills/matlab --agent cursor --scope project -f \
    && gh skill install K-Dense-AI/scientific-agent-skills skills/matplotlib --agent cursor --scope project -f \
    && npx skills@latest add https://github.com/matlab/skills --skill matlab-performance-optimizer -a cursor -y --copy
}

run_update() {
  # Never: npx skills@latest update mattpocock/skills
  npx skills@latest update -p -y
}

case "$action" in
  local-only)
    echo "bootstrap: SKIPPED_LOCAL_ONLY"
    ;;
  node-missing)
    echo "bootstrap: NODE_MISSING"
    ;;
  fresh)
    echo "bootstrap: SKIPPED_FRESH"
    ;;
  name-guard-fail)
    echo "bootstrap: NAME_GUARD_FAIL owned skill collision: ${collisions:-unknown}" >&2
    echo "bootstrap: OK"
    exit 1
    ;;
  setup)
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "bootstrap: WOULD_SETUP"
    elif run_setup; then
      echo "bootstrap: SETUP_OK"
      stamp_pref
    else
      echo "bootstrap: SYNC_FAILED_CONTINUE (using vendored skills in .agents/skills/)" >&2
    fi
    ;;
  update)
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "bootstrap: WOULD_UPDATE"
    elif run_update; then
      echo "bootstrap: UPDATE_OK"
      stamp_pref
    else
      echo "bootstrap: SYNC_FAILED_CONTINUE (using vendored skills in .agents/skills/)" >&2
    fi
    ;;
  *)
    echo "bootstrap: FAIL unknown action '$action'" >&2
    exit 1
    ;;
esac

echo "bootstrap: OK"
