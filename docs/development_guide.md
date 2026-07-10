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
- `matlab`, `matlab-performance-optimizer`

Project commands (`/build`, `/new`, `/modify`, `/accept`, `/explain`) — **`/accept`** implemented (T3); T4–T7 pending.

## Template smoke (T1)

From the repository root:

```bash
./scripts/template-smoke.sh
```

Validates staging folders, seed magnitude types under `codes/`, empty catalog (no `.m`), readable spec/templates, and bootstrap skill tests. Run after scaffold changes or before release.

```bash
./scripts/test-bootstrap-skills.sh   # bootstrap staleness logic only
./scripts/test-accept-bundle.sh      # /accept promotion and validation
```

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
