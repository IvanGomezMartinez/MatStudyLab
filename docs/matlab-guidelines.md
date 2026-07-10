# MATLAB Guidelines — MatStudyLab

Baseline conventions for readable optical-lab MATLAB scripts. Aimed at technicians with limited programming experience.

**Precedence:** `LORE.md` (user overrides) > this document > MathWorks defaults.

**Full research:** `.scratch/matstudylab/assets/research-matlab-guidelines.md` (not committed; reference only).

---

## 1. File naming

### MATLAB hard constraints

| Rule | Notes |
|------|-------|
| Names start with a letter; letters, digits, underscores only | Valid `isvarname` |
| Function file name must match the first function name | Required for functions |
| Stay well under 64 characters | Readability over R2025a 2048-char limit |

### MatStudyLab conventions

| Artifact | Convention | Example |
|----------|------------|---------|
| Type folder under `codes/` | English kebab-case | `mtf/`, `strehl-ratio/`, `iol-profiles/` |
| `.m` script | English snake_case, **no verb prefix** | `through_focus_mtf.m` |
| `.m` function (if used) | lowerCamelCase (MathWorks) or per LORE | `computeStrehlRatio.m` |
| Companion `.md` | Same stem as `.m` | `through_focus_mtf.md` |

The type folder gives optical context; do not repeat magnitude in every filename.

### Folder placement

| Main purpose | Folder |
|--------------|--------|
| MTF, OTF, edge response | `codes/mtf/` |
| PSF, spot, blur | `codes/psf/` |
| Strehl, peak vs diffraction limit | `codes/strehl-ratio/` |
| FFT/spectrum as the **goal** | `codes/fourier-transform/` |
| IOL profiles, stitching | `codes/iol-profiles/` |
| Zernike, wavefront | `codes/zernikes/` |
| Moiré patterns | `codes/moire/` |

Use `fourier-transform/` only when spectral analysis is the goal, not an intermediate step toward MTF/PSF.

---

## 2. Variables

1. **Full optical words** in the top `%% Parameters` block.
2. **Units in names** when not dimensionless: `_um`, `_mm`, `_deg`, `_cyc_per_mm`.
3. **Avoid single-letter names** except universal optics symbols (`lambda`, `NA`, `f`) with a one-line comment on first use.
4. **One concept per variable** — prefer `mtf_at_50_cyc_per_deg` over `x`.
5. **Plural suffix** for collections: `field_angles_deg`, `zernike_coefficients`.

```matlab
%% Parameters (edit these)
wavelength_um = 0.55;
pixel_size_um = 3.45;
cutoff_frequency_cyc_per_mm = 50;
```

---

## 3. Scripts vs functions

| Situation | Use | Why |
|-----------|-----|-----|
| Default catalog script | **Script** | User edits parameters, presses Run, inspects Workspace |
| Reused by ≥2 scripts | **Local function** at bottom of script | Keeps catalog flat |
| Stable utility (e.g. `psf_to_mtf`) | **Function file** in same folder or `codes/_shared/` | Independent testing |
| Batch / API | **Function** with `arguments` block | Input validation |

### Script template

```matlab
%% Title — one line purpose

%% Parameters (edit these)

%% Load data

%% Compute

%% Plot

%% Local functions (if any)
```

---

## 4. Comments and structure

| Audience | Inline `.m` | Companion `.md` |
|----------|-------------|-----------------|
| Learning (default) | `%%` section headers only | Full optical context, theory |
| Confident use | Section headers; parameters documented | Reference-style I/O |
| Production | Minimal; assert critical assumptions | Run instructions + expected outputs |

- Use `%%` sections (enables Run Section).
- One space after `%`.
- ≤120 characters per line; 4-space indent.
- **Do not** line-comment every statement — pedagogy lives in `.md`.
- Keep function bodies ≤20 lines where possible; extract named blocks when needed.

---

## 5. Console output

Per LORE (default: figures + key numbers):

```matlab
VERBOSE = true;  % or read from LORE.md

if VERBOSE
    fprintf('Strehl ratio: %.3f\n', strehl_ratio);
    fprintf('Cutoff frequency: %.1f cyc/mm\n', cutoff_cyc_per_mm);
end
```

- `fprintf` for 3–5 labeled results with units.
- Label plot axes with units.
- Avoid dumping large arrays to the console.

---

## 6. Performance

Invoke `matlab-performance-optimizer` when:

- Script processes large images, loops over fields/zones, or FFT volumes (`/new`, `/modify`).
- User reports slowness or change adds nested loops.
- `/build` batch has redundant per-file patterns.

**Do not** invoke for `/explain` or routine `/accept`.

Default policy: optimize only when profiling shows a bottleneck or runtime exceeds interactive patience. Readability wins until then.

Core techniques: vectorize, preallocate, prefer built-ins (`fft2`, `imfilter`, `psf2otf`), profile before optimizing.

---

## 7. Toolboxes

Document in every companion `.md`:

```markdown
## Requirements
- MATLAB R20xx or later
- Image Processing Toolbox
- (optional) Signal Processing Toolbox
```

| Tier | Toolbox | Typical use |
|------|---------|-------------|
| Core | MATLAB base | `fft2`, plotting, `imread` |
| Essential | Image Processing Toolbox | `imfilter`, `psf2otf`, deconvolution |
| Common | Signal Processing Toolbox | 1D spectra, windowing |

AI must only use toolboxes listed in `LORE.md`.

---

## 8. Content split (LORE vs `.m` vs `.md`)

| Content | LORE.md | `.m` | Companion `.md` |
|---------|---------|------|-----------------|
| Equipment, default units | ✅ | | |
| Never-use rules | ✅ | | |
| Editable parameters | | ✅ `%% Parameters` | Explain meaning |
| Executable logic | | ✅ | |
| Optical theory, learning | | | ✅ |
| Toolbox requirements | | brief | ✅ full list |
| Step-by-step for beginners | | `%%` names | ✅ |

---

## 9. Pairing rule

Every catalog script: `name.m` + `name.md` in the same bundle folder. Optional `explain_name.md` after `/explain` → `/accept`.

Commands `/new`, `/modify`, `/build` use `docs/templates/script-companion.md`.
