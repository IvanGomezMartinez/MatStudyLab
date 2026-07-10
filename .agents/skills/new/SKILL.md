---
name: new
description: "Create a new MATLAB script and base companion in new/ after grill-me checklist."
disable-model-invocation: true
---

Create a new script + base companion in `new/<type>/<bundle>/` after mandatory grill-me. **Write only under `new/`** — never edit `codes/` in situ.

Read `LORE.md`, `AGENTS.md`, `docs/spec.md`, `docs/matlab-guidelines.md`, and `CONTEXT.md` before acting.

## Step 0 — Bootstrap (mandatory)

Read and execute `.agents/skills/matstudylab-bootstrap/SKILL.md` before any other step.
Do not proceed until bootstrap completes (sync, skip, or failed-with-continue).

## Step 1 — Read context

| Always | On demand |
|--------|-----------|
| `LORE.md`, `AGENTS.md` | Related bundles under `codes/<type>/` |
| `docs/templates/script-companion.md` | Similar scripts elsewhere in `codes/` |

**Completion criterion:** equipment, units, and naming prefs from LORE are loaded.

## Step 2 — Grill-me checklist (mandatory before code)

Run `.agents/skills/grill-me/SKILL.md` and confirm all five items:

```bash
./scripts/new-scaffold.sh checklist
```

1. Optical magnitude + target `codes/<type>/` folder  
2. Units / equipment  
3. Inputs, outputs, console behavior  
4. `snake_case` filename without verb prefix  
5. Companion `.md` language  

Validate the filename:

```bash
./scripts/new-scaffold.sh validate <stem>
```

**Do not generate code until grill-me passes.**

**Completion criterion:** user confirmed all five checklist items.

## Step 3 — Generate with MATLAB skills (mandatory)

**Read and apply both vendored MATLAB skills** before writing or revising any `.m` file:

| Skill | Path | Role |
|-------|------|------|
| **matlab** | `.agents/skills/matlab/SKILL.md` | Syntax, scripts, matrices, graphics, best practices |
| **matlab-performance-optimizer** | `.agents/skills/matlab-performance-optimizer/SKILL.md` | Vectorization, memory, profiling when performance matters |

These skills are **installed manually** in `.agents/skills/` (not synced by `matstudylab-bootstrap` for now — see deferred note below). If either file is missing, stop and tell the user to install them before generating code.

**Completion criterion:** both skill files were read and their guidance applied to the script.

Rules (after skills):

- Optimal MATLAB per `docs/matlab-guidelines.md`; pedagogy in `.md`, not line comments in `.m`
- `%%` sections only in `.m`; parameters in top `%% Parameters` block
- Default to **scripts** (not functions) unless reuse requires otherwise
- `snake_case` stem without verb prefix; bundle folder matches stem for 1:1 pairs

**Completion criterion:** script content matches the grilled requirements and MATLAB skills guidance.

## Step 4 — Scaffold output paths

After generation, ensure files land at:

```bash
./scripts/new-scaffold.sh scaffold <type> <bundle> <stem>
```

Then replace scaffold placeholders with final script and companion content.

Output:

- `new/<type>/<bundle>/<stem>.m`
- `new/<type>/<bundle>/<stem>.md`

**Completion criterion:** both files exist under `new/` with matching stems; no writes outside `new/`.

## Step 5 — Recommend `/accept`

Tell the user:

```text
/accept new
```

when the bundle is ready for catalog promotion.

**Completion criterion:** user knows how to promote the bundle.

## Safety (non-negotiable)

- Write **only** under `new/`.
- Never edit `codes/` in situ.
- Never change units without warning; never delete measurement data.

## Reference

- Wayfinder spec: `.scratch/matstudylab/issues/06-grilling-comando-new.md`
- Companion template: `docs/templates/script-companion.md`
- MATLAB skills (mandatory): `.agents/skills/matlab/SKILL.md`, `.agents/skills/matlab-performance-optimizer/SKILL.md`
- Optional tools: `ask-matt`, `research` when design is unclear

### Deferred

Auto-sync of MATLAB skills via `skills-lock.json` / bootstrap — out of scope for now; skills stay manually vendored.
