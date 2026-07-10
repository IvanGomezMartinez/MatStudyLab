# Companion `.md` template

Use this structure for every `codes/<type>/<bundle>/<name>.md` paired with `<name>.m`.

**Language:** write in the user's preferred language (ask on first `/build` or `/new`; store in `LORE.md`). Folder paths and filenames stay in **English**.

---

## Blank template (copy per script)

```markdown
# <Human-readable title>

> Script: `codes/<type>/<bundle>/<name>.m`  
> Last updated: YYYY-MM-DD

## Purpose

One paragraph: what lab problem this solves and when you would use it.

## Optical context

- **Equipment / bench:** (see also `LORE.md`)
- **Sample / lens / eye model:**
- **Conditions:** temperature, medium (air/water), illumination…
- **Units:** (e.g. cyc/deg, µm, mm) and how they relate to other quantities

## Before you run

1. Open `<name>.m` in MATLAB.
2. Edit the `%% Parameters` section if needed.
3. Required data files: `path/...`

## What the code does (step by step)

Each step maps to a `%%` section in the `.m`:

| Step | `.m` section | What happens |
|------|--------------|--------------|
| 1 | `%% Parameters` | … |
| 2 | `%% Load data` | … |
| 3 | `%% Compute` | … |
| 4 | `%% Plot` | … |

## Design decisions

- **Why this approach:** …
- **Alternatives not used:** …

## How to run

1. Press **Run** (or **Run Section** block by block).
2. **Expected figures:** …
3. **Console (key numbers):** … (e.g. `MTF @ 50 cyc/deg = 0.42`)

## Requirements

- **MATLAB:** R20xx or later
- **Toolboxes:** Image Processing Toolbox, …

## Programming concepts (learning)

Plain-language notes on MATLAB ideas used here (vectors, `interp2`, `fft2`, …).

## Related scripts

- `codes/<type>/<other_bundle>/<other>.m` — …

## History

| Date | Change |
|------|--------|
| YYYY-MM-DD | Initial creation |
```

---

## Rules for `/new`, `/modify`, `/build`, `/explain`

1. Always create `<name>.md` next to `<name>.m` (same stem).
2. Map each `%%` section in `.m` to a row in "What the code does".
3. Put equipment ↔ unit relationships in `LORE.md`; reference them from "Optical context".
4. Keep long theory here; keep `.m` to `%%` sections + parameters only.
5. Console: document which key numbers appear (figures + `fprintf` per LORE).

See `docs/templates/LORE.md` for the filled example (synthetic MTF) in the scratch prototype at `.scratch/matstudylab/assets/template-script-companion.md`.
