# MatStudyLab — Development Guide

Developer documentation for implementing and maintaining MatStudyLab. End-user information lives in [README.md](../README.md).

## Specification

The implementation contract is **[docs/spec.md](./spec.md)** — commands, folder layout, safety rules, bundle model, testing seams, and ticket order T1–T8.

Supporting docs:

| File | Purpose |
|------|---------|
| [CONTEXT.md](../CONTEXT.md) | Domain glossary |
| [AGENTS.md](../AGENTS.md) | Agent conventions and skills pointers |
| [matlab-guidelines.md](./matlab-guidelines.md) | MATLAB baseline (trimmed from wayfinder research) |
| [templates/script-companion.md](./templates/script-companion.md) | Base companion `.md` template |
| [templates/explain-doc.md](./templates/explain-doc.md) | Deep study `explain_<stem>.md` template |
| [templates/LORE.md](./templates/LORE.md) | LORE.md template |

## Wayfinder status

Wayfinding is **complete** (2026-07-10). Closed tickets live in `.scratch/matstudylab/issues/` (01–09, 11–14). The map is at `.scratch/matstudylab/map.md`.

**Destination:** fully functional repo — not spec-only. Spec consolidation (`/to-spec`) precedes implementation.

## Post-wayfinder workflow

```
/to-spec      → docs/spec.md, CONTEXT.md, AGENTS.md, templates (DONE)
/to-tickets   → T1–T8 tracer bullets with blocking edges
/implement    → one ticket per fresh agent session (Pocock skill: .agents/skills/implement/)
/audit        → quality gates per ticket
/qa           → full validation when all tickets done
```

**`/implement` sources:** ticket file under `.scratch/matstudylab/issues/` (or `tickets.md` frontier) plus `docs/spec.md`. No `docs/plans/` — that JIRA-style layout is not used in this repo.

Run `/setup-matt-pocock-skills` if `docs/agents/` is missing (already scaffolded for local-markdown tracker).

## Implementation ticket order

From [spec.md](./spec.md):

```
T1  Scaffold + AGENTS.md + LORE.md template + docs/templates/
    └─ T2  matstudylab-bootstrap skill (skills-lock sync ≤24h)
         └─ T3  /accept skill
              ├─ T4  /explain skill
              ├─ T5  /build skill
              └─ T6  /new skill
                   └─ T7  /modify skill
                        └─ T8  E2E: codigosRealesNoSubir subset → import/ → /build
```

Each command skill:

- **Step 0:** read and execute `matstudylab-bootstrap` (automatic skills sync when stale)
- User-invoked (`disable-model-invocation: true`)
- Validated with `writing-great-skills`
- Steps + completion criteria
- Pointers to `docs/templates/` and `LORE.md`

## Issue tracker

Local markdown: `.scratch/matstudylab/`. See [docs/agents/issue-tracker.md](./agents/issue-tracker.md).

Implementation PRD: `.scratch/matstudylab/PRD.md` (`ready-for-agent`).

## Skills

Vendored in `.agents/skills/` per `skills-lock.json`:

- Pocock engineering skills (`implement`, `to-tickets`, `grill-me`, …)
- `matlab`, `matlab-performance-optimizer` — manually vendored; **mandatory for `/new` and `/modify`** (read both `SKILL.md` files). Bootstrap auto-sync for these: **deferred**.

All five workflow commands implemented (T3–T7). **T8 E2E** — see [E2E pipeline validation](#e2e-pipeline-validation-t8) below.

## QA (release validation)

When tickets **15–22** are complete, run from the repository root:

```bash
./scripts/qa.sh
```

**Last run:** 2026-07-10 — **PASS** (template smoke + 7 test suites + skill presence + empty `codes/`).

Checks:

| Gate | Command / criterion |
|------|---------------------|
| Template scaffold | `./scripts/template-smoke.sh` |
| Per-command seams | `test-bootstrap`, `test-accept`, `test-explain`, `test-build`, `test-new`, `test-modify` |
| E2E pipeline | `./scripts/test-e2e-pipeline.sh` |
| Project skills | `matstudylab-bootstrap`, `accept`, `explain`, `build`, `new`, `modify`, `matlab`, `matlab-performance-optimizer` |
| Privacy | `codes/` has no `.m`; `codigosRealesNoSubir/` gitignored when present |

**Manual follow-up (not automated):** one real bundle from `codigosRealesNoSubir/` through agent-invoked `/build` → `/explain` → `/accept` in Cursor.

## Template smoke (T1)

From the repository root:

```bash
./scripts/template-smoke.sh
```

Validates staging folders, seed magnitude types under `codes/`, empty catalog (no `.m`), readable spec/templates, and bootstrap skill tests. Run after scaffold changes or before release.

```bash
./scripts/test-bootstrap-skills.sh   # bootstrap staleness logic only
./scripts/test-accept-bundle.sh      # /accept promotion and validation
./scripts/test-explain-bundle.sh     # /explain paths and scaffold
./scripts/test-build-import.sh       # /build scan, catalog, homonym
./scripts/test-new-bundle.sh          # /new scaffold and naming
./scripts/test-modify-bundle.sh       # /modify catalog copy mirror
./scripts/test-e2e-pipeline.sh       # T8 import → build → explain → accept
```

## E2E pipeline validation (T8)

Validates the full workflow seam: **`import/` → `/build` → `/explain` → `/accept modify`** with safety assertions. Does **not** run MATLAB or assert numerical correctness.

### Automated (committed fixture)

```bash
./scripts/test-e2e-pipeline.sh
```

Uses `scripts/fixtures/e2e/iol_profiles_bundle/synthetic_iol_profile.m` copied into a temp workspace:

| Step | Simulates | Asserts |
|------|-----------|---------|
| `/build` | `catalog_from_import` → `codes/iol-profiles/synthetic_iol_profile/` | `import/` cleared for cataloged bundle; base `.md` drafted |
| `/explain` | `explain_*.md` under `explain/` | **No in-situ edit** of `.m` in `codes/` |
| `/accept modify` | `modify-copy` + `accept_bundle` | `explain_*.md` attached in catalog; `modify/` cleared |

Orchestration: `scripts/lib/e2e_pipeline.py`.

### Manual lab subset (optional, local only)

When `codigosRealesNoSubir/` exists on your machine:

1. Copy **one small folder** (e.g. a single-bundle candidate under `PERFILES_IOLs/`) into `import/<type>/<bundle>/`.
2. Run `/build` with grill-me and confirm `iol-profiles/` (or the right magnitude).
3. Run `/explain` on the cataloged `.m`.
4. Run `/accept modify` to attach the study doc.

**Do not commit** `codigosRealesNoSubir/` or cataloged proprietary `.m` files. Ticket 10 (full inventory) remains deferred.

### Safety assertions (verified by E2E)

- AI never edits `codes/` in situ — only via confirmed `/build` catalog or `/accept` promotion.
- `/explain` writes only under `explain/`; catalog `.m` bytes unchanged during explain.
- `/build` deletes from `import/` only what was cataloged in the session.
- Measurement data moves with the bundle folder; no orphan deletion outside the confirmed import tree.

### Known limits

- No automated MATLAB execution or optical numerical validation.
- `codigosRealesNoSubir/` is gitignored — CI uses the synthetic fixture only.
- `matlab` / `matlab-performance-optimizer` skills are manually vendored (bootstrap auto-sync deferred).
- Homonym handling and grill-me gates are skill-level (human/agent); the automated E2E tests the **script seams** only.

## Local E2E test bank

`codigosRealesNoSubir/` — ~50 real lab scripts, **gitignored**, never commit. Used for T8 validation only.

## Privacy

- Template upstream: empty `codes/` (`.gitkeep` only)
- No proprietary `.m` in public/private template repo
- `.scratch/` gitignored (wayfinder artifacts stay local)

## Language

- Repo artifacts: English
- Communicate with Iván: Spanish
- User-facing companion `.md`: per `LORE.md` (default Spanish for current user)

## Open questions (TBD)

See [spec.md — Further Notes](./spec.md#further-notes): catalog semver, numerical validation, CI/CD, multi-harness details.
