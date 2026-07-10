# MatStudyLab

Domain language for an AI-assisted MATLAB workspace used by optical lab technicians to create, catalog, import, and learn scripts for real laboratory work.

## Workflow

**Catalog**:
The stable, approved collection of script bundles under `codes/<type>/<bundle>/`. Source of truth; AI never edits in place.
_Avoid_: Repository, library, production folder

**Staging**:
Temporary work areas (`new/`, `modify/`, `explain/`) where AI writes drafts before user acceptance into the catalog.
_Avoid_: Sandbox (too informal), workspace (ambiguous with MATLAB workspace)

**Import**:
The intake folder where users dump existing scripts in any subfolder tree before `/build` classifies them into the catalog.
_Avoid_: Inbox, upload folder

**Bundle**:
A catalog unit under `codes/<type>/<bundle>/` — one or more `.m` files plus a base companion `.md`, optionally `explain_*.md` after study.
_Avoid_: Package, module, project folder

## Classification

**Magnitude** (`<type>/`):
The primary optical quantity a script measures or computes (e.g. MTF, PSF, Strehl). Determines the kebab-case folder under `codes/`.
_Avoid_: Category, tag, domain

**Type folder**:
English kebab-case directory under `codes/` grouping bundles by magnitude (`mtf/`, `iol-profiles/`, `zernikes/`).
_Avoid_: Namespace, module path

## Documents

**Base companion** (`<stem>.md`):
Paired `.md` next to a script — usage, optical context, step-by-step mapped to `%%` sections. Created by `/new`, `/build`, or `/modify`.
_Avoid_: README, docstring, help file

**Explain doc** (`explain_<stem>.md`):
Deep-study document from `/explain` — theory, improvement ideas (not implemented), MATLAB concepts. Attached to catalog on `/accept`.
_Avoid_: Tutorial, deep-dive markdown (unqualified)

**LORE**:
User memory file at repo root — equipment, units, preferences, folder map, never-do rules. Read by every command; overrides style defaults but not safety rules.
_Avoid_: Config, preferences file, user profile

## Commands

**Build**:
Onboarding command that scans `import/`, proposes bundle classification, and moves confirmed bundles into `codes/` incrementally.
_Avoid_: Import command, ingest

**Accept**:
Promotion command that moves approved bundles from `new/` or `modify/` into `codes/`, optionally attaching `explain_*.md` and running git per LORE.
_Avoid_: Merge, publish, deploy

## Safety

**In-situ edit**:
Modifying a file directly in `codes/` without copying to `modify/` first. Forbidden for AI.
_Avoid_: Direct edit, hotfix

**Copy-first modify**:
Required pattern: `/modify` copies `codes/<type>/<bundle>/` to `modify/<type>/<bundle>/` before any `.m` change.
_Avoid_: Branch, fork

## Naming

**Stem**:
Filename without extension shared by a script and its base companion (`through_focus_mtf` for `.m` and `.md`).
_Avoid_: Slug, basename (when ambiguous with git)

**Snake case (script names)**:
`through_focus_mtf.m` — descriptive, no verb prefix; the type folder gives optical context.
_Avoid_: camelCase for catalog scripts (unless LORE explicitly overrides for functions)
