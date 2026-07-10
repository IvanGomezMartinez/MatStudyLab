# MatStudyLab — Agent Instructions

Private portfolio/template repo for optical lab technicians using AI-assisted MATLAB workflows.

## Project conventions

- **Technical artifacts** (code, specs, skills, this file): English.
- **Companion `.md` and LORE content**: user's preferred language (default Spanish); see `LORE.md`.
- **Developer communication** with Iván: Spanish.
- **Spec contract**: `docs/spec.md` — commands, folders, safety rules, bundle model.
- **Domain glossary**: `CONTEXT.md` — use defined terms; avoid synonyms listed under _Avoid_.
- **MATLAB baseline**: `docs/matlab-guidelines.md`; `LORE.md` overrides personal style, never safety rules.
- **Templates**: `docs/templates/script-companion.md`, `docs/templates/LORE.md`.

## Safety (non-negotiable)

- Never edit `codes/` in situ. Write only in `new/`, `modify/`, `explain/`.
- `/modify` on catalog content: copy to `modify/` first.
- Never change units without warning; never delete/overwrite measurement data; never use unavailable toolboxes.

## Agent skills

### Issue tracker

Local markdown under `.scratch/<feature>/` (wayfinder map and tickets). Implementation PRD at `.scratch/matstudylab/PRD.md`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles with default strings (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo: `CONTEXT.md` at root; ADRs in `docs/adr/` when created. See `docs/agents/domain.md`.

### Vendored skills

Installed under `.agents/skills/` per `skills-lock.json`:

- Pocock engineering: `to-spec`, `to-tickets`, `implement`, `grill-me`, `writing-great-skills`, etc.
- MATLAB: `matlab`, `matlab-performance-optimizer`
- `matstudylab-bootstrap` — not user-facing; runs as Step 0 inside `/build`, `/new`, `/modify`, `/accept`, `/explain`

Project command skills (`/build`, `/new`, `/modify`, `/accept`, `/explain`) are **not yet implemented** — see `docs/spec.md` ticket order T1–T8.

## Before touching code

1. Read `LORE.md` (if present).
2. Read `docs/spec.md` for the command or area in scope.
3. Read `CONTEXT.md` for domain terms.
4. For MATLAB generation: invoke `matlab` and `matlab-performance-optimizer` skills.
