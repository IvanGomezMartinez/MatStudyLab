---
name: modify
description: "Copy a catalog bundle to modify/ and adapt one script per session."
disable-model-invocation: true
---

Adapt a catalog bundle by copying `codes/<type>/<bundle>/` to `modify/<type>/<bundle>/` before any edit. **Never edit `codes/` in situ.**

Read `LORE.md`, `AGENTS.md`, `docs/spec.md`, `docs/matlab-guidelines.md`, and `CONTEXT.md` before acting.

## Step 0 — Bootstrap (mandatory)

Read and execute `.agents/skills/matstudylab-bootstrap/SKILL.md` before any other step.
Do not proceed until bootstrap completes (sync, skip, or failed-with-continue).

## Step 1 — Select bundle and script

- `/modify` without hint → ask which catalog bundle to adapt.
- **One main script per session** by default.
- If subscripts are involved → ask whether to edit together or one file per session.

**Completion criterion:** target `codes/<type>/<bundle>/` and main `.m` are identified.

## Step 2 — Copy catalog → modify (mandatory)

```bash
./scripts/modify-copy.sh <type> <bundle>
```

Copies the **entire bundle folder** (N:1 sets included). Reuses existing `modify/` copy unless `MODIFY_OVERWRITE=1`.

**Do not edit any file until this copy succeeds.**

**Completion criterion:** `modify/<type>/<bundle>/` exists and `codes/` is unchanged.

## Step 3 — Grill-me on changes

Run `.agents/skills/grill-me/SKILL.md` on **what changes** — behavior, plots, outputs, units — not the whole script from scratch.

If base companion `.md` is missing or incomplete, run the full `/new` checklist first.

**Completion criterion:** user confirmed intended changes.

## Step 4 — Edit in `modify/` only

Apply changes to `.m` and companion `.md` under `modify/<type>/<bundle>/`.

Invoke `.agents/skills/matlab/SKILL.md` and `.agents/skills/matlab-performance-optimizer/SKILL.md` when changing code.

- Rename `.m` + `.md` together if purpose changes (user confirmation).
- Update `.md` history / relevant sections with each meaningful change.

**Completion criterion:** edits exist only under `modify/`; companion reflects the new behavior.

## Step 5 — Recommend `/accept modify`

Ask whether to promote now or keep iterating:

```text
/accept modify
```

**Completion criterion:** user knows how to promote or continue editing.

## Safety (non-negotiable)

- **Never** write to `codes/` except via `/accept` or confirmed `/build`.
- Write **only** under `modify/` after the mandatory copy step.
- Never change units without warning; never delete measurement data.

## Reference

- Wayfinder spec: `.scratch/matstudylab/issues/07-grilling-comando-modify.md`
- Companion template: `docs/templates/script-companion.md`
