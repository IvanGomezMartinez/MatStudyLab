# MatStudyLab — Development Guide

Developer documentation for implementing and maintaining MatStudyLab. End-user information lives in [README.md](../README.md).

## Specification

The implementation contract is **[docs/spec.md](./spec.md)** — commands, folder layout, safety rules, bundle model, and testing seams.

Supporting docs:

| File | Purpose |
|------|---------|
| [CONTEXT.md](../CONTEXT.md) | Domain glossary |
| [AGENTS.md](../AGENTS.md) | Agent conventions and skills pointers |
| [matlab-guidelines.md](./matlab-guidelines.md) | MATLAB baseline |
| [templates/script-companion.md](./templates/script-companion.md) | Base companion `.md` template |
| [templates/explain-doc.md](./templates/explain-doc.md) | Deep study `explain_<stem>.md` template |
| [templates/LORE.md](./templates/LORE.md) | LORE.md template |

## Skills

Vendored in `.agents/skills/` per `skills-lock.json`:

- Pocock engineering skills (`implement`, `to-tickets`, `grill-me`, …)
- `matlab`, `matlab-performance-optimizer` — manually vendored; **mandatory for `/new` and `/modify`** (read both `SKILL.md` files). Bootstrap auto-sync for these: **deferred**.

All five workflow commands are implemented (`/accept`, `/explain`, `/build`, `/new`, `/modify`). Each command skill:

- **Step 0:** read and execute `matstudylab-bootstrap` (automatic skills sync when stale)
- User-invoked (`disable-model-invocation: true`)
- Checked by `./scripts/validate-command-skills.sh` (structure aligned with `writing-great-skills`)
- Steps + completion criteria
- Pointers to `docs/templates/` and `LORE.md`

## QA

From the repository root:

```bash
./scripts/qa.sh
```

Runs workflow seam tests only — command skill structure, bootstrap staleness, and per-command script behavior (`/accept`, `/explain`, `/build`, `/new`, `/modify`) plus the synthetic E2E pipeline. Does **not** run MATLAB or assert numerical correctness.

Individual suites:

```bash
./scripts/validate-command-skills.sh
./scripts/test-bootstrap-skills.sh
./scripts/test-accept-bundle.sh
./scripts/test-explain-bundle.sh
./scripts/test-build-import.sh
./scripts/test-new-bundle.sh
./scripts/test-modify-bundle.sh
./scripts/test-e2e-pipeline.sh
```

## E2E pipeline

Validates **`import/` → `/build` → `/explain` → `/accept modify`** with safety assertions using a committed synthetic fixture:

```bash
./scripts/test-e2e-pipeline.sh
```

| Step | Simulates | Asserts |
|------|-----------|---------|
| `/build` | `catalog_from_import` → `codes/iol-profiles/synthetic_iol_profile/` | `import/` cleared for cataloged bundle; base `.md` drafted |
| `/explain` | `explain_*.md` under `explain/` | **No in-situ edit** of `.m` in `codes/` |
| `/accept modify` | `modify-copy` + `accept_bundle` | `explain_*.md` attached in catalog; `modify/` cleared |

Orchestration: `scripts/lib/e2e_pipeline.py`. Fixture: `scripts/fixtures/e2e/iol_profiles_bundle/`.

### Safety assertions (verified by E2E)

- AI never edits `codes/` in situ — only via confirmed `/build` catalog or `/accept` promotion.
- `/explain` writes only under `explain/`; catalog `.m` bytes unchanged during explain.
- `/build` deletes from `import/` only what was cataloged in the session.

### Known limits

- No automated MATLAB execution or optical numerical validation.
- Homonym handling and grill-me gates are skill-level (human/agent); automated tests cover **script seams** only.

## Privacy

- Template upstream ships without proprietary laboratory `.m` files in `codes/`.
- `.scratch/` is gitignored (local planning artifacts).

## Language

- Repo artifacts: English
- User-facing companion `.md`: per `LORE.md` (default Spanish for current user)

## Open questions (TBD)

See [spec.md — Further Notes](./spec.md#further-notes): catalog semver, numerical validation, CI/CD, multi-harness details.
