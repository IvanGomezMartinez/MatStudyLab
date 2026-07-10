# MatStudyLab — Implementation Specification

**Status:** ready-for-agent  
**Source:** Wayfinder map (`.scratch/matstudylab/map.md`) + closed tickets 01–09, 11–14  
**Destination:** Fully functional AI-assisted MATLAB workflow for optical lab technicians

---

## Problem Statement

Optical lab technicians (optometrists, imaging specialists) need reliable MATLAB scripts for real laboratory work — MTF, PSF, IOL profiles, Zernike analysis, and more — but have limited programming experience. They need a safe, guided workflow to create, adapt, catalog, import, and learn from scripts without risking their stable catalog or measurement data. Generic AI coding assistants lack domain structure, safety boundaries, and persistent user context.

## Solution

MatStudyLab is a private portfolio/template repository that provides folder structure, conventions, companion documentation, and five user-invoked AI commands. Scripts live in a versioned **catalog** (`codes/`) with paired `.md` companions. All AI writes go through **staging** areas (`new/`, `modify/`, `explain/`) or **import** intake (`import/`). User preferences, equipment, and units persist in `LORE.md`. The template ships empty; each user brings their own scripts under their control.

## User Stories

1. As an optical lab technician, I want to dump my existing MATLAB scripts into `import/` with any folder structure, so that I can onboard my lab catalog without manual reorganization first.
2. As an optical lab technician, I want `/build` to scan `import/`, propose optical-magnitude bundles, and move them incrementally into `codes/`, so that I catalog scripts safely with my confirmation at each step.
3. As an optical lab technician, I want `/build` to ask my preferred companion `.md` language on first use and remember it, so that documentation matches how I read best.
4. As an optical lab technician, I want `/new` to create a new script and base companion in `new/` after a guided checklist, so that I can add lab workflows without touching the stable catalog.
5. As an optical lab technician, I want `/new` to read my equipment and units from `LORE.md`, so that generated scripts use my lab conventions automatically.
6. As an optical lab technician, I want `/modify` to copy a catalog bundle to `modify/` before any edit, so that my stable `codes/` copy stays intact until I explicitly accept.
7. As an optical lab technician, I want `/modify` to handle one script per session and ask about subscripts, so that changes stay focused and reviewable.
8. As an optical lab technician, I want `/accept` to move approved bundles from `new/` or `modify/` into `codes/`, so that staging work becomes my official catalog.
9. As an optical lab technician, I want `/accept` to attach deep-study `explain_*.md` files when present, so that learning notes travel with the script into the catalog.
10. As an optical lab technician, I want `/accept` to respect my git workflow preference (`local-only` vs `own-repo`), so that version control matches how I work.
11. As an optical lab technician, I want `/explain` to produce `explain_<stem>.md` without changing `.m` files, so that I can study scripts safely.
12. As an optical lab technician, I want companion `.md` files to map each `%%` section to plain-language steps, so that I understand what the code does without reading every line.
13. As an optical lab technician, I want console output to show key numbers and figures, so that I get immediate optical results when I press Run.
14. As an optical lab technician, I want `.m` files to use `%%` sections only (no line-by-line comments), so that the Editor stays clean and the `.md` carries the teaching.
15. As an optical lab technician, I want file names in `snake_case` without verb prefixes, so that names stay readable and the folder gives optical context.
16. As an optical lab technician, I want scripts classified by optical magnitude first (`mtf/`, `psf/`, `iol-profiles/`), so that I find related work intuitively.
17. As an optical lab technician, I want `fourier-transform/` only when spectral analysis is the goal, so that FFT-as-intermediate-step scripts stay with their magnitude folder.
18. As an optical lab technician, I want the AI to never change units without warning, so that I do not misinterpret measurement results.
19. As an optical lab technician, I want the AI to never delete or overwrite measurement data files, so that my raw captures stay safe.
20. As an optical lab technician, I want the AI to only use MATLAB toolboxes I have listed, so that scripts run on my machine without license errors.
21. As an optical lab technician, I want the AI to never edit `codes/` in place, so that my catalog cannot be corrupted by a single mistaken session.
22. As an optical lab technician, I want new `codes/` subfolders proposed and confirmed with context saved to `LORE.md`, so that future classifications stay consistent.
23. As a developer (Iván), I want the template repo to ship without proprietary `.m` files, so that users fork a clean structure and bring their own scripts.
24. As a developer, I want `codigosRealesNoSubir/` gitignored for local E2E testing, so that real lab scripts never leak to upstream.
25. As a developer, I want Matt Pocock engineering skills vendored in `.agents/skills/` with `skills-lock.json`, so that the workflow is reproducible across clones.
26. As a developer, I want each command implemented as a user-invoked skill (`disable-model-invocation: true`), so that commands run only when explicitly requested.
27. As a developer, I want command skills validated with `writing-great-skills`, so that agent behavior is consistent and auditable.
28. As a developer, I want `matlab` and `matlab-performance-optimizer` skills invoked for code generation, so that scripts follow MathWorks best practices.
29. As a developer, I want `grill-me` mandatory before `/new` and `/build` code generation, so that requirements are confirmed before any file is written.
30. As a developer, I want `docs/matlab-guidelines.md` as the baseline with `LORE.md` overrides, so that personal style does not fork project conventions silently.
31. As a developer, I want harness-agnostic skills under `.agents/skills/`, so that Cursor, Claude Code, or other agents can run the same commands.
32. As a developer, I want incremental `/build` that deletes from `import/` only what was cataloged in the session, so that large imports can be processed over multiple days.
33. As a developer, I want homonym detection when a bundle name already exists in `codes/`, so that imports do not silently overwrite catalog entries.
34. As a developer, I want `/accept` to block when a bundle lacks `.m` or `.md`, so that incomplete work cannot enter the catalog.
35. As a developer, I want bundle naming to support 1:1 (one `.m` per bundle), N:1 (multiple `.m` + one `.md`), or AI-proposed pipeline names with user confirmation, so that real lab folder structures map cleanly.
36. As a developer, I want `explain/` as a study staging area separate from `modify/`, so that learning and editing workflows do not collide.
37. As a developer, I want LORE decision log entries after confirmed folder moves, so that classification history is traceable.
38. As a developer, I want README and `docs/development_guide.md` to document post-wayfinder workflow (`/to-tickets` → `/implement`), so that the next implementation phase is clear.
39. As a developer, I want `matstudylab-bootstrap` to run automatically at the start of every workflow command (`/new`, `/build`, `/accept`, `/explain`, `/modify`) and sync `skills-lock.json` when stale (>24h), so that vendored skills stay current without a separate manual step.
40. As a developer, I want E2E validation with a subset of `codigosRealesNoSubir/` through `import/` → `/build`, so that the full pipeline is proven on real lab scripts before release.

## Implementation Decisions

### Repository model

- **Template upstream:** empty `codes/` (`.gitkeep` only); MIT license for structure, docs, and skills.
- **User fork/clone:** user adds scripts via `import/`, `/new`, or manual staging; proprietary content stays in their repo.
- **`codigosRealesNoSubir/`:** local-only E2E test bank (~50 scripts); gitignored; never committed.

### Folder layout

```
MatStudyLab/
├── LORE.md                          # User memory — read by every command
├── import/                          # Intake — any subfolder tree; /build source
├── codes/<type>/<bundle>/           # Catalog — source of truth
│   ├── <script>.m
│   ├── <stem>.md                    # Base companion (/new, /build draft)
│   └── explain_<stem>.md            # Deep study doc (/explain → /accept)
├── new/<type>/<bundle>/             # Staging — /new output
├── modify/<type>/<bundle>/          # Staging — mirror of codes; /modify edits copy only
└── explain/                         # Study targets; outputs explain_<stem>.md
```

### Taxonomy (`<type>/`)

- English **kebab-case** folder names; open list.
- Seed types: `mtf/`, `psf/`, `fourier-transform/`, `strehl-ratio/`, `iol-profiles/`, `zernikes/`, `moire/`, and others as confirmed.
- **Classification rule:** optical magnitude first; `fourier-transform/` only when spectral analysis is the **goal**, not an intermediate step toward MTF/PSF/etc.

### Bundle naming

- Interior `<bundle>/` folder: same name as main `.m` (1:1), or bundle `.md` name (N:1), or pipeline name proposed by AI + user confirm.
- `.m` files: `snake_case` **without** verb prefix (folder gives type context).
- Companion `.md`: same stem as primary `.m` for 1:1 pairs.

### Document types

| File | Role |
|------|------|
| `<stem>.md` | Base companion — usage, run instructions, optical context |
| `explain_<stem>.md` | Deep learning doc — improvements (not implemented), MATLAB concepts, user Q&A |
| `LORE.md` | User memory — equipment, units, prefs, never-do, git workflow, `.md` language |

### Safety rules (non-negotiable)

- AI **never** edits files in `codes/` in situ.
- AI writes only in `new/`, `modify/`, `explain/`; reads `import/` and `codes/` as context.
- `/modify` on `codes/` → **copy** to `modify/` first, edit copy only.
- Never: change units without warning; delete/overwrite measurement data; use unavailable paid toolboxes.

### Command contracts

| Command | Contract |
|---------|----------|
| `/build` | Scan `import/` recursively; propose bundles; grill-me; move to `codes/` incrementally; delete only cataloged files from `import/`; draft base `.md`; LORE log |
| `/new` | Optional hint; mandatory grill-me (5-point checklist); read LORE+AGENTS; codes/ on demand; output `new/<type>/<bundle>/`; matlab skills; recommend `/accept` |
| `/modify` | One script/session (ask if subscripts); copy codes→modify; grill what changes; update `.md`; recommend `/accept modify` |
| `/accept` | Variants: default/`all`, `new`, `modify`; move bundles; attach `explain_*.md`; git per LORE (`local-only` vs `own-repo`) |
| `/explain` | No `.m` changes; `explain_<stem>.md`; zoom-out heuristics; handoff internally; recommend `/accept` |

### `/new` pre-code checklist (mandatory via grill-me)

1. Optical magnitude + `codes/<type>/` folder
2. Units / equipment
3. Inputs, outputs, console behavior
4. `snake_case` filename without verb
5. Companion `.md` language

### `/build` onboarding

On first run, if missing from `LORE.md`: companion `.md` language, git workflow (`local-only` / `own-repo`).

### `/accept` requirements

- 1:1: `.m` + `.md` with matching stems.
- N:1: ≥1 `.m` + one `.md`.
- Block if `.m` missing; block if `.md` missing (offer to generate).
- From `modify/`: replaces existing bundle in `codes/`.
- Attaches `explain_*.md` from `explain/` when present.

### Code quality

- Invoke `matlab` + `matlab-performance-optimizer` skills for generation.
- Optimal MATLAB per `docs/matlab-guidelines.md`; pedagogy in `.md`, not by dumbing down code.
- Default catalog scripts are **scripts** (not functions); local functions at bottom when reused.
- `%%` sections only in `.m`; parameters in top `%% Parameters` block.
- Console: figures + key numbers via `fprintf` (per LORE).

### Skills layout

- Vendored in `.agents/skills/`: Pocock engineering skills, `matlab`, `matlab-performance-optimizer`.
- `skills-lock.json` committed; includes `last_checked` (ISO timestamp) updated after each successful sync check.
- **`matstudylab-bootstrap` (T2):** not a user-facing slash command. `disable-model-invocation: true`. Every workflow command skill (T3–T7) **must** start with **Step 0**: read and execute `.agents/skills/matstudylab-bootstrap/SKILL.md` — sync upstream skills when lockfile age >24h, skip when fresh, then proceed.
- Project command skills (T3–T7): user-invoked, `writing-great-skills` validated, pointers to `docs/templates/` and `LORE.md`.

### Language policy

- Repo technical artifacts: **English**.
- Companion `.md` and `LORE.md` content: **user's preferred language** (default Spanish for current user); stored in LORE.
- Developer communication with Iván: Spanish.

### Implementation ticket order (post-spec)

```
T1  Scaffold + AGENTS.md + LORE.md template + docs/templates/
    └─ T2  matstudylab-bootstrap skill (skills-lock sync ≤24h)
         └─ T3  /accept skill
              ├─ T4  /explain skill
              ├─ T5  /build skill
              └─ T6  /new skill
                   └─ T7  /modify skill
                        └─ T8  E2E: subset codigosRealesNoSubir → import/ → /build
```

## Testing Decisions

### What makes a good test

Test **external behavior** of the workflow — folder moves, file presence, safety boundaries, and command completion criteria — not internal skill implementation details or MATLAB numerical correctness.

### Primary seam (one integration boundary)

**User-invoked command skills** are the single highest seam. Each skill (`build`, `new`, `modify`, `accept`, `explain`) is validated against its completion criteria: correct staging paths, no in-situ `codes/` writes, grill-me gates, LORE reads, and recommended next-command handoffs.

### Secondary validation

| Layer | What | When |
|-------|------|------|
| **E2E pipeline** | Subset of `codigosRealesNoSubir/` → `import/` → `/build` → `/explain` → `/accept` | T8 — after all command skills exist |
| **Safety assertions** | Agent session must not create/modify files under `codes/` except via `/accept` or confirmed `/build` move | Every command skill audit |
| **Bootstrap** | Staleness check + sync runs as Step 0 of every workflow command (T3–T7); skipped when lockfile age ≤24h | T2 + every command skill audit |
| **Template smoke** | Fresh clone has empty `codes/`, scaffold folders, templates, and readable spec | T1 |

### Prior art

- Pocock `writing-great-skills` — skill structure, steps, completion criteria.
- Pocock `implement` skill — per-ticket fresh-context implementation.
- Wayfinder closed tickets — command behavior already grilled; tests assert those contracts.

### Not in scope for automated tests (TBD)

- Numerical validation of optical script outputs.
- CI/CD beyond manual git from `/accept`.
- Catalog semver / changelog policy.

## Out of Scope

- Implementing command skills in this spec phase (deferred to T1–T8).
- Publishing proprietary lab catalog to template upstream.
- Generic MATLAB training unrelated to optical lab work.
- Web UI or app outside repo + AI editor workflow.
- Re-litigating closed wayfinder decisions (see `.scratch/matstudylab/issues/`).
- Committing `codigosRealesNoSubir/` or `.scratch/` content.

## Further Notes

### Open questions (TBD)

- Catalog semver / changelog policy per bundle or per `<type>/`.
- Automated numerical validation of optical scripts against reference data.
- CI/CD (GitHub Actions vs manual-only from `/accept`).
- Multi-harness IA beyond Cursor — design is harness-agnostic via `.agents/skills/`.

### Deferred work

- Ticket 10: final inventory/classification of `codigosRealesNoSubir/` with end user (E2E input, not spec blocker).

### References

- Wayfinder map: `.scratch/matstudylab/map.md`
- Closed command specs: `.scratch/matstudylab/issues/06`–`09`, `11`
- User preferences: `.scratch/matstudylab/issues/14-hitl-preferencias-usuaria-optica.md`
- Domain glossary: `CONTEXT.md`
- MATLAB baseline: `docs/matlab-guidelines.md`
- Templates: `docs/templates/script-companion.md`, `docs/templates/LORE.md`
