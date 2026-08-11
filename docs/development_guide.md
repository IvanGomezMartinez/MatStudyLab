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
| [templates/skills-pref.example.json](./templates/skills-pref.example.json) | Schema example for the tooling preference sidecar (`mode`, `last_synced_at`) |

## Skills

Vendored in `.agents/skills/` per `skills-lock.json`:

- Pocock engineering skills (`implement`, `to-tickets`, `grill-me`, …)
- `matlab`, `matlab-performance-optimizer` — included in bootstrap setup/update; **mandatory to read both `SKILL.md` files for `/new` and `/modify`** (see [matlab-skills-gate.md](./agents/matlab-skills-gate.md))

### Orchestrator v2 and Step 0

`matstudylab-bootstrap` is the harness-agnostic orchestrator (not a user-facing slash command). Every workflow command (`/accept`, `/explain`, `/build`, `/new`, `/modify`) starts with **Step 0**: read and execute that skill. The script chooses **setup** vs **update** (or skip), gates on Node/`npx`, and records freshness in a gitignored preference sidecar (see the example template above). Details: [command-skill-step-0.md](./agents/command-skill-step-0.md).

Each command skill:

- **Step 0:** execute `matstudylab-bootstrap`
- User-invoked (`disable-model-invocation: true`)
- Checked by `./scripts/validate-command-skills.sh` (structure aligned with `writing-great-skills`)
- Steps + completion criteria
- Pointers to `docs/templates/` and `LORE.md`

### `/build` HITL (short)

When preference `mode` is `local-only`, `/build` skips Node/network and may offer re-enable → `auto`. When `auto` and sync cannot complete (missing Node, sync failure, or incomplete setup), `/build` presents three options: continue this session, save `local-only`, or open setup. Other commands warn briefly and continue on vendored skills. Manual checklist: [build-skills-hitl-checklist.md](./agents/build-skills-hitl-checklist.md).

## QA

From the repository root:

```bash
./scripts/qa.sh
```

Runs workflow seam tests only — command skill structure, **local skills integrity** (`./scripts/check-skills-integrity.sh`: lock + on-disk skills; no upstream network), bootstrap staleness, release-check unit tests, and per-command script behavior (`/accept`, `/explain`, `/build`, `/new`, `/modify`) plus the synthetic E2E pipeline. Does **not** run MATLAB or assert numerical correctness. Does **not** enforce release freshness against the live preference sidecar.

Individual suites:

```bash
./scripts/validate-command-skills.sh
./scripts/check-skills-integrity.sh
./scripts/test-bootstrap-skills.sh
./scripts/test-vendor-release.sh
./scripts/test-accept-bundle.sh
./scripts/test-explain-bundle.sh
./scripts/test-build-import.sh
./scripts/test-new-bundle.sh
./scripts/test-modify-bundle.sh
./scripts/test-e2e-pipeline.sh
```

## Maintainer release checklist (A+C)

Refresh the committed vendor tree before tagging a release.

### A — Setup/update and commit

1. **Name-guard:** before a bulk Pocock add, confirm no planned upstream skill name collides with owned skills (`accept`, `build`, `explain`, `new`, `modify`, `matstudylab-bootstrap`). Abort if any collision.
2. Run orchestrator setup/update (or the literal CLI below). Prefer **`--copy`** so `.agents/skills/` stays file copies suitable for git (not install-cache symlinks).
3. Review `skills-lock.json` and `.agents/skills/` diff; commit; tag.

Literal CLI (`skills@1.5.22+` contract):

```bash
# Setup (incomplete / first-time catalog) — always --copy for public vendor
npx skills@latest add mattpocock/skills --skill '*' -a cursor -y --copy
npx skills@latest add https://github.com/k-dense-ai/claude-scientific-skills \
  --skill matlab -a cursor -y --copy
npx skills@latest add https://github.com/matlab/skills \
  --skill matlab-performance-optimizer -a cursor -y --copy

# Update (all lock origins; never pass a repo id as update positional)
npx skills@latest update -p -y
```

Owned command skills stay **out** of `skills-lock.json`.

### C — Release freshness

```bash
./scripts/check-vendor-release.sh
```

Fails if `last_synced_at` is missing or older than 24h. Override with `BOOTSTRAP_PREF` / `BOOTSTRAP_NOW_ISO` in tests only. Daily `./scripts/qa.sh` does **not** run this against live upstream.

**Fallback (lock-only clones):** if a fork commits only `skills-lock.json` and empties `.agents/skills/`, `npx skills@latest experimental_install` can restore lock entries into `.agents/skills/`. This template vendors the skill trees in git, so that path is optional.

## E2E pipeline

Validates **`import/` → `/build` → `/explain` → `/accept explain`** with safety assertions using a committed synthetic fixture:

```bash
./scripts/test-e2e-pipeline.sh
```

| Step | Simulates | Asserts |
|------|-----------|---------|
| `/build` | `catalog_from_import` → `codes/iol-profiles/synthetic_iol_profile/` | `import/` cleared for cataloged bundle; base `.md` drafted |
| `/explain` | `explain_*.md` under `explain/` | **No in-situ edit** of `.m` in `codes/` |
| `/accept explain` | `accept_explain_attachments` | `explain_*.md` copied into catalog; sources removed from `explain/` |

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
