---
name: build
description: "Scan import/ and catalog optical script bundles into codes/ incrementally."
disable-model-invocation: true
---

Onboard lab scripts from `import/` into `codes/<type>/<bundle>/` with user confirmation at each step. The only `/build` write path into `codes/` is a **confirmed catalog move** — never edit existing catalog bundles in situ.

Read `LORE.md`, `AGENTS.md`, `docs/spec.md`, and `CONTEXT.md` before acting.

## Step 0 — Bootstrap (mandatory)

Read and execute `.agents/skills/matstudylab-bootstrap/SKILL.md` before any other step.
Do not proceed until bootstrap completes (sync, skip, or failed-with-continue).

**Completion criterion:** bootstrap outcome identified (fresh, synced, or failed-with-continue).

## Step 1 — LORE onboarding (first run)

If `LORE.md` is missing or lacks companion `.md` language / git workflow, ask the user and write answers to `LORE.md` from `docs/templates/LORE.md`.

**Completion criterion:** companion language and git workflow are recorded (or user declined onboarding).

## Step 2 — Scan `import/`

```bash
./scripts/build-import.sh scan
```

Recursively list bundle proposals grouped by folder under `import/`.

**Completion criterion:** the user sees proposed bundles and optical magnitude (`<type>/`) for each.

## Step 3 — Grill-me (mandatory before any write)

Run `.agents/skills/grill-me/SKILL.md` (→ `/grilling`) on the catalog plan: types, bundle names, 1:1 vs N:1, files to move, and what stays in `import/` for later sessions.

**Do not write files until grill-me passes.**

**Completion criterion:** user confirmed the catalog plan.

## Step 4 — Homonym check

For each bundle:

```bash
./scripts/build-import.sh homonym <type> <bundle>
```

| Result | Action |
|--------|--------|
| `homonym` | Ask: skip, rename bundle, or route to `/modify` |
| `available` | Proceed to catalog |

**Completion criterion:** every bundle has a resolved homonym decision.

## Step 5 — Catalog confirmed bundles

Move only user-confirmed bundles (directly to `codes/`, not via `new/`):

```bash
./scripts/build-import.sh catalog <type> <bundle> import/<path/to/folder>
```

Drafts a base companion `.md` from `docs/templates/script-companion.md` when missing.

New `codes/<type>/` folders require user confirmation; append folder map + decision log rows to `LORE.md`.

**Completion criterion:** each confirmed bundle exists under `codes/`; only cataloged files were removed from `import/`.

## Step 6 — Post-build handoff

- Recommend `/explain` for priority scripts.
- If LORE git workflow is `own-repo`, propose a commit after user OK (`catalog: <type>/<bundle>`).

**Completion criterion:** user knows recommended next commands.

## Safety (non-negotiable)

- Never modify `codes/` without explicit user confirmation per bundle.
- Never delete from `import/` except files cataloged in this session.
- Never delete or overwrite measurement data outside the confirmed bundle folder move.

## Reference

- Wayfinder spec: `.scratch/matstudylab/issues/11-grilling-comando-build.md`
- Companion template: `docs/templates/script-companion.md`
- Homonym + incremental rules: `docs/spec.md` (`/build`, US32–33)
