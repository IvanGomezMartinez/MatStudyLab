---
name: build
description: "Scan import/ and catalog optical script bundles into codes/ incrementally."
disable-model-invocation: true
---

Onboard lab scripts from `import/` into `codes/<type>/<bundle>/` with user confirmation at each step. The only `/build` write path into `codes/` is a **confirmed catalog move** — never edit existing catalog bundles in situ.

Read `LORE.md`, `AGENTS.md`, `docs/spec.md`, and `CONTEXT.md` before acting.

English is the default for HITL copy below. Localize only when `LORE.md` or a `/build` language choice says so.

## Step 0 — Bootstrap (mandatory)

Read and execute `.agents/skills/matstudylab-bootstrap/SKILL.md` before any other step.
Do not proceed until bootstrap completes (skip, setup/update, or warn-and-continue).

**Completion criterion:** bootstrap outcome identified (skip, setup/update OK, or warn-and-continue).

## Step 1 — Skills HITL

After Step 0, branch on the bootstrap outcome. Canonical English strings live in `.scratch/skills-auto-provisioning-v2/assets/prototype-node-gate-messages.md` (Scenarios A–G). Prefer those exact texts.

Preference sidecar: `.matstudylab/skills-pref.json` (`mode`: `auto` | `local-only`, `last_synced_at`). Absence ⇒ treat as `auto`. Never auto-install Node.

### Helper — write preference mode

Preserve `last_synced_at` unless the bootstrap script just stamped it. From repo root:

```bash
python3 - <<'PY'
from pathlib import Path
import sys
sys.path.insert(0, "scripts/lib")
from skills_bootstrap import load_pref, write_pref
path = Path(".matstudylab/skills-pref.json")
data = load_pref(path)
data["mode"] = "auto"  # or "local-only"
write_pref(path, data)
PY
```

### Branch A — `local-only` (`bootstrap: SKIPPED_LOCAL_ONLY`)

Show Scenario A. Do **not** probe Node or sync.

| Choice | Action |
|--------|--------|
| Continue with /build | Proceed to Step 2 |
| Re-enable sync (switch to auto mode) | Write `mode: auto`, re-run Step 0 bootstrap, then re-enter Step 1 on the new outcome |

### Branch B — Node/`npx` missing (`bootstrap: NODE_MISSING`)

Show Scenario B (three options).

| Choice | Action |
|--------|--------|
| Continue with vendored skills (this session only) | Proceed to Step 2 (no pref write) |
| Continue and remember: do not sync (local-only) | Write `mode: local-only`, then Step 2 |
| Open setup — how to install Node and sync skills | Detect OS; print **only** the matching block from `docs/agents/skills-node-os-checklist.md`. Never auto-install. When the user has Node/`npx`, re-run Step 0; on `SETUP_OK` / `UPDATE_OK` go to Branch E |

### Branch C — Sync failed (`bootstrap: SYNC_FAILED_CONTINUE`)

Show Scenario C (include a short stderr / exit detail). Same three-option table as Branch B, except option 3 is **Retry setup/update** (re-run Step 0 when Node is present).

### Branch D — Incomplete setup (no successful sync yet)

Trigger when preference is `auto`/absent **and** setup is still incomplete after Step 0: empty/missing `skills` map in `skills-lock.json`, **or** `last_synced_at` is null, **and** you did **not** just get `SETUP_OK` / `UPDATE_OK` / `SKIPPED_FRESH`. Prefer Branch B or C when those markers also apply.

Show Scenario D. Same three options; option 3 is **Open setup — sync now** (OS checklist if no Node; else re-run Step 0).

### Branch E — Quiet success

| Outcome | Message |
|---------|---------|
| `SETUP_OK` / `UPDATE_OK` | Scenario G. Ensure `mode: auto` (script stamps `last_synced_at`). Continue to Step 2 — no menu. |
| `SKIPPED_FRESH` | Scenario E one-liner. Continue to Step 2 — no menu. |

**Completion criterion:** HITL branch resolved — user choice applied (pref written when required), quiet success acknowledged, or setup path waiting on Node install / re-bootstrap; then proceed to Step 2 only when continuing `/build` this turn.

## Step 2 — LORE onboarding (first run)

If `LORE.md` is missing or lacks companion `.md` language / git workflow, ask the user and write answers to `LORE.md` from `docs/templates/LORE.md`.

**Completion criterion:** companion language and git workflow are recorded (or user declined onboarding).

## Step 3 — Scan `import/`

```bash
./scripts/build-import.sh scan
```

Recursively list bundle proposals grouped by folder under `import/`.

**Completion criterion:** the user sees proposed bundles and optical magnitude (`<type>/`) for each.

## Step 4 — Grill-me (mandatory before any write)

Run `.agents/skills/grill-me/SKILL.md` (→ `/grilling`) on the catalog plan: types, bundle names, 1:1 vs N:1, files to move, and what stays in `import/` for later sessions.

**Do not write files until grill-me passes.**

**Completion criterion:** user confirmed the catalog plan.

## Step 5 — Homonym check

For each bundle:

```bash
./scripts/build-import.sh homonym <type> <bundle>
```

| Result | Action |
|--------|--------|
| `homonym` | Ask: skip, rename bundle, or route to `/modify` |
| `available` | Proceed to catalog |

**Completion criterion:** every bundle has a resolved homonym decision.

## Step 6 — Catalog confirmed bundles

Move only user-confirmed bundles (directly to `codes/`, not via `new/`):

```bash
./scripts/build-import.sh catalog <type> <bundle> import/<path/to/folder>
```

Drafts a base companion `.md` from `docs/templates/script-companion.md` when missing.

New `codes/<type>/` folders require user confirmation; append folder map + decision log rows to `LORE.md`.

**Completion criterion:** each confirmed bundle exists under `codes/`; only cataloged files were removed from `import/`.

## Step 7 — Post-build handoff

- Recommend `/explain` for priority scripts.
- If LORE git workflow is `own-repo`, propose a commit after user OK (`catalog: <type>/<bundle>`).

**Completion criterion:** user knows recommended next commands.

## Safety (non-negotiable)

- Never modify `codes/` without explicit user confirmation per bundle.
- Never delete from `import/` except files cataloged in this session.
- Never delete or overwrite measurement data outside the confirmed bundle folder move.
- Never auto-install Node or run package managers for the user; OS checklists are display-only.

## Reference

- Wayfinder spec: `.scratch/matstudylab/issues/11-grilling-comando-build.md`
- Companion template: `docs/templates/script-companion.md`
- Homonym + incremental rules: `docs/spec.md` (`/build`, US32–33)
- HITL decisions: `.scratch/skills-auto-provisioning-v2/issues/02-grilling-build-hitl-dialogue.md`
- Canonical English HITL copy: `.scratch/skills-auto-provisioning-v2/assets/prototype-node-gate-messages.md`
- OS install checklists: `docs/agents/skills-node-os-checklist.md`
- Manual HITL verification: `docs/agents/build-skills-hitl-checklist.md`
