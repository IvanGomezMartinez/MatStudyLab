---
name: accept
description: "Promote approved script bundles from new/ or modify/ into the catalog."
disable-model-invocation: true
---

Move validated bundles from staging (`new/`, `modify/`) into `codes/<type>/<bundle>/`. The only allowed write path into `codes/`.

Read `LORE.md` (if present), `docs/spec.md` (`/accept` requirements), and `CONTEXT.md` before acting.

## Step 0 — Bootstrap (mandatory)

Read and execute `.agents/skills/matstudylab-bootstrap/SKILL.md` before any other step.
Do not proceed until bootstrap completes (sync, skip, or failed-with-continue).

## Step 1 — Parse variant

| User input | Scope |
|------------|-------|
| `/accept`, `/accept all` | All pending bundles in `new/` and `modify/` |
| `/accept new` | Only `new/` |
| `/accept modify` | Only `modify/` |

**Completion criterion:** variant is identified.

If variant is `all` (or default) **and** both `new/` and `modify/` have pending bundles, ask: accept everything, only `new/`, or only `modify/`?

## Step 2 — Read LORE

Read `LORE.md` for:

- Git workflow (`local-only` or `own-repo`)
- Folder map context when proposing `codes/<type>/`

If `LORE.md` is missing, assume `local-only` and note it to the user.

**Completion criterion:** git workflow preference is known.

## Step 3 — List and validate pending bundles

Run:

```bash
./scripts/accept-bundle.sh <variant>
```

with `ACCEPT_DRY_RUN=1` first to validate without moving, **or** validate each bundle in Python via `scripts/lib/accept_bundle.py` before promotion.

Validation rules:

- At least one `.m` — otherwise **block**
- At least one base companion `.md` (not `explain_*.md`) — otherwise **block** and offer to generate from `docs/templates/script-companion.md`
- **1:1:** one `.m` + one `.md` with matching stems
- **N:1:** multiple `.m` + exactly one base `.md`

**Completion criterion:** every bundle in scope passes validation or the command stops with a clear block reason.

## Step 4 — Confirm destination

For each bundle, confirm `codes/<type>/<bundle>/` with the user when type or name is ambiguous. New `codes/<type>/` folders require user confirmation and a row in LORE folder map.

**Completion criterion:** user confirmed each destination path.

## Step 5 — Promote bundles

Run for real (no dry run):

```bash
./scripts/accept-bundle.sh <variant> [type bundle]
```

This moves the full bundle, clears staging, replaces an existing catalog bundle when source is `modify/`, and copies matching `explain/explain_<stem>.md` files into the catalog bundle.

**Completion criterion:** each promoted bundle exists under `codes/` and its staging folder is gone.

## Step 6 — Git per LORE

| Git workflow | Action |
|--------------|--------|
| `local-only` | Do not commit or push |
| `own-repo` | Propose commit message `catalog: <type>/<bundle>` after user OK; then ask about push to `main` |

**Completion criterion:** git behavior matches LORE.

## Step 7 — LORE decision log (optional)

After successful accept, offer a one-line entry in LORE decision log.

**Completion criterion:** user accepted or declined the log entry.

## Safety (non-negotiable)

- Never write to `codes/` except through this confirmed flow.
- Never delete measurement data files.
- From `new/`: block if `codes/<type>/<bundle>/` already exists (use `/modify` instead).

## Reference

- Wayfinder spec: `.scratch/matstudylab/issues/08-grilling-comando-accept.md`
- Companion template: `docs/templates/script-companion.md`
- Step 0 contract: `docs/agents/command-skill-step-0.md`
