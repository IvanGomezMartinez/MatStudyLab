# LORE.md template

This file is read by every workflow command (`/new`, `/modify`, `/accept`, `/explain`, `/build`).
It stores **your** lab context and preferences. Generic MATLAB rules live in `docs/matlab-guidelines.md`; **LORE overrides** those defaults for personal style, never safety rules.

**Who edits this file**

| Actor | Rule |
|-------|------|
| **You** | Edit freely anytime. |
| **AI** | May **propose** additions (folder context, reclassifications, prefs). Appends only **after you confirm**. Never deletes your notes without asking. |
| **Maintenance** | If LORE grows past ~200 lines, the AI may offer a short summary section at the top — you approve before restructuring. |

---

## Blank template (copy to repo root as `LORE.md`)

```markdown
# LORE — <your name or lab>

> MatStudyLab personal context. The AI reads this before touching code.

## Preferences

| Key | Value |
|-----|-------|
| Companion `.md` language | es / en / … |
| Git workflow | local-only / own-repo (onboarding; affects `/accept`) |
| Console output | key numbers + figures / quiet / verbose |
| `.m` comments | `%%` sections only |
| File naming | snake_case, no verb prefix (folder gives type) |

## Lab equipment

| Equipment | Role | Notes |
|-----------|------|-------|
| | | |

## Units and relationships

| Quantity | Unit we use | Relates to |
|----------|-------------|------------|
| Spatial frequency | cyc/deg (cycles per degree) | … |
| Length / profile | µm | … |

## Folder map (`codes/`)

| Folder | What belongs here | Notes |
|--------|-------------------|-------|
| `mtf/` | MTF, OTF, edge response | |
| `psf/` | PSF, spot, blur | |
| `fourier-transform/` | Spectral analysis as **goal** (not intermediate step) | |
| `strehl-ratio/` | Strehl, peak vs diffraction | |
| `iol-profiles/` | IOL profiling, stitching, … | |
| `zernikes/` | Zernike polynomials, wavefront | |
| `moire/` | Moiré patterns | |

## MATLAB toolboxes available

- MATLAB base
- Image Processing Toolbox: yes / no
- Signal Processing Toolbox: yes / no
- Other:

## Coding style (personal)

- Figures: size in mm? colormap?
- Parameters: top `%% Parameters` block always
- Scripts vs functions: prefer scripts unless reuse needed

## Learning progress

- Comfortable:
- Still learning:

## Never do (safety)

- Do not change units without explicit warning and my OK
- Do not delete or overwrite measurement data files
- Do not use toolboxes not listed above
- Do not edit files in `codes/` — only `new/` and `modify/`; copy from `codes/` to `modify/` first

## Decision log

| Date | Decision |
|------|----------|
| | |
```

---

## Rules for commands

1. **Read LORE first** — before generating or moving any script.
2. **On first `/build` or `/new`** — if companion `.md` language is empty, ask and write here.
3. **New manual folder in `codes/`** — user gives context → append row to "Folder map".
4. **After confirmed `/accept` or `/build`** — optional one-line entry in "Decision log".
5. **Overrides** — LORE wins over `docs/matlab-guidelines.md` for personal style; never overrides safety "Never do".
