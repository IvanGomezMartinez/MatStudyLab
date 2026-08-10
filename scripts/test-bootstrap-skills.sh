#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0

assert_eq() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $label — expected '$expected', got '$actual'" >&2
    failures=$((failures + 1))
  fi
}

assert_contains() {
  local label="$1"
  local needle="$2"
  local haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "FAIL: $label — output missing '$needle'" >&2
    echo "$haystack" >&2
    failures=$((failures + 1))
  fi
}

assert_not_contains() {
  local label="$1"
  local needle="$2"
  local haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "FAIL: $label — output unexpectedly contains '$needle'" >&2
    echo "$haystack" >&2
    failures=$((failures + 1))
  fi
}

python_is_stale() {
  python3 - "$@" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path("scripts/lib")))
from skills_bootstrap import is_stale

last_synced_at = sys.argv[1] if sys.argv[1] != "NONE" else None
now = datetime.fromisoformat(sys.argv[2].replace("Z", "+00:00"))
print("stale" if is_stale(last_synced_at, now) else "fresh")
PY
}

python_decide() {
  python3 - "$@" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path("scripts/lib")))
from skills_bootstrap import decide_sync_action

lock = json.loads(sys.argv[1])
pref = json.loads(sys.argv[2])
now = datetime.fromisoformat(sys.argv[3].replace("Z", "+00:00"))
print(decide_sync_action(lock, pref, now))
PY
}

fresh_result="$(python_is_stale "2026-07-10T12:00:00.000Z" "2026-07-10T13:00:00.000Z")"
assert_eq "fresh last_synced_at within 24h" "fresh" "$fresh_result"

stale_result="$(python_is_stale "2026-07-09T10:00:00.000Z" "2026-07-10T13:00:00.000Z")"
assert_eq "stale last_synced_at after 24h" "stale" "$stale_result"

missing_result="$(python_is_stale "NONE" "2026-07-10T13:00:00.000Z")"
assert_eq "missing last_synced_at is stale" "stale" "$missing_result"

# Unit: decide_sync_action
assert_eq "decide local-only" "local-only" "$(
  python_decide '{"skills":{"grill-me":{}}}' '{"mode":"local-only","last_synced_at":null}' "2026-07-10T14:30:00.000Z"
)"
assert_eq "decide setup when never synced" "setup" "$(
  python_decide '{"skills":{"grill-me":{}}}' '{"mode":"auto","last_synced_at":null}' "2026-07-10T14:30:00.000Z"
)"
assert_eq "decide setup when empty skills map" "setup" "$(
  python_decide '{"skills":{}}' '{"mode":"auto","last_synced_at":"2026-07-10T10:00:00.000Z"}' "2026-07-10T14:30:00.000Z"
)"
assert_eq "decide update when stale" "update" "$(
  python_decide '{"skills":{"grill-me":{}}}' '{"mode":"auto","last_synced_at":"2026-07-08T10:00:00.000Z"}' "2026-07-10T14:30:00.000Z"
)"
assert_eq "decide fresh within window" "fresh" "$(
  python_decide '{"skills":{"grill-me":{}}}' '{"mode":"auto","last_synced_at":"2026-07-10T10:00:00.000Z"}' "2026-07-10T14:30:00.000Z"
)"

# Unit: name-guard
name_guard_result="$(
  python3 <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import name_guard_collisions

print(",".join(name_guard_collisions(["grill-me", "accept", "matlab"])))
PY
)"
assert_eq "name-guard finds owned collision" "accept" "$name_guard_result"

name_guard_clean="$(
  python3 <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import name_guard_collisions

print(",".join(name_guard_collisions(["grill-me", "matlab"])) or "none")
PY
)"
assert_eq "name-guard clean planned set" "none" "$name_guard_clean"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Missing preference file → auto + never synced (stale)
missing_pref="$tmpdir/missing-pref.json"
missing_pref_json="$(python3 - "$missing_pref" <<'PY'
import json
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import load_pref

pref = load_pref(Path(sys.argv[1]))
print(json.dumps({"mode": pref["mode"], "last_synced_at": pref["last_synced_at"]}))
PY
)"
assert_eq "missing pref defaults to auto/null" '{"mode": "auto", "last_synced_at": null}' "$missing_pref_json"

cp skills-lock.json "$tmpdir/skills-lock.json"
pref_fresh="$tmpdir/skills-pref-fresh.json"
python3 - "$pref_fresh" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import touch_last_synced_at

path = Path(sys.argv[1])
updated = touch_last_synced_at(path, datetime(2026, 7, 10, 14, 0, tzinfo=timezone.utc))
print(updated)
PY

# Capture lock last_checked before bootstrap so we prove we no longer write it
lock_before="$(python3 - "$tmpdir/skills-lock.json" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("last_checked", "ABSENT"))
PY
)"

fresh_output="$(
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$pref_fresh" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh
)"
assert_contains "fresh bootstrap skips sync" "bootstrap: SKIPPED_FRESH" "$fresh_output"
assert_contains "fresh bootstrap completes" "bootstrap: OK" "$fresh_output"

pref_after_fresh="$(python3 - "$pref_fresh" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["last_synced_at"])
PY
)"
assert_eq "SKIPPED_FRESH stamps last_synced_at" "2026-07-10T14:30:00.000Z" "$pref_after_fresh"

lock_after="$(python3 - "$tmpdir/skills-lock.json" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("last_checked", "ABSENT"))
PY
)"
assert_eq "bootstrap does not rewrite lock last_checked" "$lock_before" "$lock_after"

# Stale sidecar → WOULD_UPDATE; lock last_checked must be ignored; dry-run must NOT stamp
cp skills-lock.json "$tmpdir/skills-lock-stale.json"
pref_stale="$tmpdir/skills-pref-stale.json"
python3 - "$pref_stale" "$tmpdir/skills-lock-stale.json" <<'PY'
import json
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

pref_path = Path(sys.argv[1])
lock_path = Path(sys.argv[2])
write_pref(pref_path, {"mode": "auto", "last_synced_at": "2026-07-08T10:00:00.000Z"})
# Poison the lock with a "fresh" last_checked — bootstrap must ignore it
data = json.loads(lock_path.read_text(encoding="utf-8"))
data["last_checked"] = "2026-07-10T14:00:00.000Z"
lock_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

stale_output="$(
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock-stale.json" \
  BOOTSTRAP_PREF="$pref_stale" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh
)"
assert_contains "stale bootstrap dry-run update" "bootstrap: WOULD_UPDATE" "$stale_output"
assert_contains "stale bootstrap completes" "bootstrap: OK" "$stale_output"
assert_not_contains "stale dry-run is not setup" "bootstrap: WOULD_SETUP" "$stale_output"

pref_after_stale="$(python3 - "$pref_stale" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["last_synced_at"])
PY
)"
assert_eq "WOULD_UPDATE does not stamp last_synced_at" "2026-07-08T10:00:00.000Z" "$pref_after_stale"

# Missing pref / never synced → setup path (not update)
missing_pref_path="$tmpdir/does-not-exist.json"
missing_output="$(
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$missing_pref_path" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh
)"
assert_contains "missing pref bootstrap dry-run setup" "bootstrap: WOULD_SETUP" "$missing_output"
assert_contains "missing pref bootstrap completes" "bootstrap: OK" "$missing_output"
assert_not_contains "missing pref is not update" "bootstrap: WOULD_UPDATE" "$missing_output"
assert_eq "missing pref dry-run does not create sidecar" "false" "$(
  [[ -f "$missing_pref_path" ]] && echo true || echo false
)"

# Empty skills map → WOULD_SETUP even with a recent last_synced_at
empty_lock="$tmpdir/skills-lock-empty.json"
pref_empty="$tmpdir/skills-pref-empty.json"
python3 - "$empty_lock" "$pref_empty" <<'PY'
import json
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

Path(sys.argv[1]).write_text(
    json.dumps({"version": 1, "skills": {}}, indent=2) + "\n", encoding="utf-8"
)
write_pref(Path(sys.argv[2]), {"mode": "auto", "last_synced_at": "2026-07-10T10:00:00.000Z"})
PY

empty_output="$(
  BOOTSTRAP_LOCKFILE="$empty_lock" \
  BOOTSTRAP_PREF="$pref_empty" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh
)"
assert_contains "empty lock dry-run setup" "bootstrap: WOULD_SETUP" "$empty_output"
assert_contains "empty lock completes" "bootstrap: OK" "$empty_output"

# Fresh + no Node still SKIPPED_FRESH (Node only required for setup/update)
pref_fresh_nonode="$tmpdir/skills-pref-fresh-nonode.json"
python3 - "$pref_fresh_nonode" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import touch_last_synced_at

touch_last_synced_at(Path(sys.argv[1]), datetime(2026, 7, 10, 14, 0, tzinfo=timezone.utc))
PY

fresh_nonode_output="$(
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$pref_fresh_nonode" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_FORCE_NO_NODE=1 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh
)"
assert_contains "fresh without node still skips" "bootstrap: SKIPPED_FRESH" "$fresh_nonode_output"
assert_not_contains "fresh without node is not NODE_MISSING" "bootstrap: NODE_MISSING" "$fresh_nonode_output"

# NODE_MISSING — no stamp, still OK
pref_node="$tmpdir/skills-pref-node.json"
python3 - "$pref_node" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

write_pref(Path(sys.argv[1]), {"mode": "auto", "last_synced_at": "2026-07-08T10:00:00.000Z"})
PY

node_output="$(
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$pref_node" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_FORCE_NO_NODE=1 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh
)"
assert_contains "missing node outcome" "bootstrap: NODE_MISSING" "$node_output"
assert_contains "missing node still OK" "bootstrap: OK" "$node_output"
assert_not_contains "missing node skips update" "bootstrap: WOULD_UPDATE" "$node_output"

pref_after_node="$(python3 - "$pref_node" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["last_synced_at"])
PY
)"
assert_eq "NODE_MISSING does not stamp" "2026-07-08T10:00:00.000Z" "$pref_after_node"

# local-only skips network/node
pref_local="$tmpdir/skills-pref-local.json"
python3 - "$pref_local" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

write_pref(Path(sys.argv[1]), {"mode": "local-only", "last_synced_at": None})
PY

local_output="$(
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$pref_local" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_FORCE_NO_NODE=1 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh
)"
assert_contains "local-only outcome" "bootstrap: SKIPPED_LOCAL_ONLY" "$local_output"
assert_contains "local-only completes" "bootstrap: OK" "$local_output"
assert_not_contains "local-only skips node message" "bootstrap: NODE_MISSING" "$local_output"

# Name-guard FAIL when planned install collides with owned skill
pref_guard="$tmpdir/skills-pref-guard.json"
python3 - "$pref_guard" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

write_pref(Path(sys.argv[1]), {"mode": "auto", "last_synced_at": None})
PY

set +e
guard_output="$(
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$pref_guard" \
  BOOTSTRAP_DRY_RUN=1 \
  BOOTSTRAP_PLANNED_SKILLS="grill-me,accept,matlab" \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh 2>&1
)"
guard_status=$?
set -e
assert_eq "name-guard exits non-zero" "1" "$guard_status"
assert_contains "name-guard fail outcome" "bootstrap: NAME_GUARD_FAIL" "$guard_output"

# SYNC_FAILED_CONTINUE via fake npx — no stamp
fake_bin="$tmpdir/fake-bin"
mkdir -p "$fake_bin"
cat > "$fake_bin/npx" <<'EOF'
#!/usr/bin/env bash
echo "fake npx refusing sync" >&2
exit 1
EOF
chmod +x "$fake_bin/npx"

pref_fail="$tmpdir/skills-pref-fail.json"
python3 - "$pref_fail" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

write_pref(Path(sys.argv[1]), {"mode": "auto", "last_synced_at": "2026-07-08T10:00:00.000Z"})
PY

fail_output="$(
  PATH="$fake_bin:$PATH" \
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$pref_fail" \
  BOOTSTRAP_DRY_RUN=0 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh 2>&1
)"
assert_contains "sync failure outcome" "bootstrap: SYNC_FAILED_CONTINUE" "$fail_output"
assert_contains "sync failure still OK" "bootstrap: OK" "$fail_output"

pref_after_fail="$(python3 - "$pref_fail" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["last_synced_at"])
PY
)"
assert_eq "SYNC_FAILED does not stamp" "2026-07-08T10:00:00.000Z" "$pref_after_fail"

# Successful update stamps via fake npx
cat > "$fake_bin/npx" <<'EOF'
#!/usr/bin/env bash
# Accept only project-scoped update, never update <owner/repo>
if [[ "$*" == "skills@latest update -p -y" ]]; then
  exit 0
fi
echo "unexpected npx invocation: $*" >&2
exit 2
EOF
chmod +x "$fake_bin/npx"

pref_ok="$tmpdir/skills-pref-ok.json"
python3 - "$pref_ok" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

write_pref(Path(sys.argv[1]), {"mode": "auto", "last_synced_at": "2026-07-08T10:00:00.000Z"})
PY

ok_output="$(
  PATH="$fake_bin:$PATH" \
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$pref_ok" \
  BOOTSTRAP_DRY_RUN=0 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh 2>&1
)"
assert_contains "update success outcome" "bootstrap: UPDATE_OK" "$ok_output"
assert_contains "update success completes" "bootstrap: OK" "$ok_output"

pref_after_ok="$(python3 - "$pref_ok" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["last_synced_at"])
PY
)"
assert_eq "UPDATE_OK stamps last_synced_at" "2026-07-10T14:30:00.000Z" "$pref_after_ok"

# Successful setup stamps via fake npx (three adds)
cat > "$fake_bin/npx" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  "skills@latest add mattpocock/skills --skill * -a cursor -y --copy") exit 0 ;;
  "skills@latest add https://github.com/k-dense-ai/claude-scientific-skills --skill matlab -a cursor -y --copy") exit 0 ;;
  "skills@latest add https://github.com/matlab/skills --skill matlab-performance-optimizer -a cursor -y --copy") exit 0 ;;
  *)
    echo "unexpected setup npx: $*" >&2
    exit 2
    ;;
esac
EOF
chmod +x "$fake_bin/npx"

pref_setup_ok="$tmpdir/skills-pref-setup-ok.json"
python3 - "$pref_setup_ok" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from skills_bootstrap import write_pref

write_pref(Path(sys.argv[1]), {"mode": "auto", "last_synced_at": None})
PY

setup_ok_output="$(
  PATH="$fake_bin:$PATH" \
  BOOTSTRAP_LOCKFILE="$tmpdir/skills-lock.json" \
  BOOTSTRAP_PREF="$pref_setup_ok" \
  BOOTSTRAP_DRY_RUN=0 \
  BOOTSTRAP_NOW_ISO="2026-07-10T14:30:00.000Z" \
  ./scripts/bootstrap-skills.sh 2>&1
)"
assert_contains "setup success outcome" "bootstrap: SETUP_OK" "$setup_ok_output"
assert_contains "setup success completes" "bootstrap: OK" "$setup_ok_output"

pref_after_setup="$(python3 - "$pref_setup_ok" <<'PY'
import json
import sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["last_synced_at"])
PY
)"
assert_eq "SETUP_OK stamps last_synced_at" "2026-07-10T14:30:00.000Z" "$pref_after_setup"

if [[ "$failures" -gt 0 ]]; then
  echo "bootstrap-skills tests: $failures failure(s)" >&2
  exit 1
fi

echo "bootstrap-skills tests: OK"
