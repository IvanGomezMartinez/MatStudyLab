# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-08-11

Skills auto-provisioning v2 — backward-compatible template enhancement.

### Added

- Preference sidecar (gitignored) for skills sync `mode` (`auto` | `local-only`) and `last_synced_at` (24h freshness)
- Bootstrap setup path: full Pocock catalog + both MATLAB skills (`--copy`), with Node/`npx` gate and owned-skill name-guard
- `/build` HITL when sync cannot run: continue this session, save `local-only`, or open setup (OS install checklists)
- Daily skills integrity check in QA; separate release freshness gate (`check-vendor-release.sh`)
- README notes for optional Node, auto-update, and `/build` skills sync options

### Changed

- `matstudylab-bootstrap` orchestrator documents setup|update outcomes; MATLAB skills are included in sync (no longer deferred)
- Sync freshness no longer stored as `last_checked` inside `skills-lock.json` (skills CLI strips unknown keys)

### Notes

- Before tagging: run orchestrator setup/update, then `./scripts/check-vendor-release.sh`, then commit refreshed `.agents/skills/` + `skills-lock.json` if needed.
- Recommend semver **1.1.0** (minor): new capabilities without breaking the existing command/catalog contract for lab users.

## [1.0.0] - 2026-07-10

First stable template release.

### Added

- Five user-invoked workflow commands as agent skills: `/build`, `/new`, `/modify`, `/accept`, `/explain`
- `/accept explain` variant to attach study docs from `explain/` without staging through `modify/`
- Safety model: AI never edits `codes/` in place; writes only through staging areas or confirmed `/build` moves
- `LORE.md` template for persistent lab context (equipment, units, preferences)
- Companion documentation model: base `<stem>.md` and optional `explain_<stem>.md`
- Vendored agent skills under `.agents/skills/` with automatic bootstrap sync (`matstudylab-bootstrap`)
- QA suite (`./scripts/qa.sh`) and E2E pipeline: `import/` → `/build` → `/explain` → `/accept explain`
- Implementation spec, development guide, MATLAB guidelines, and domain glossary

### Notes

- Template ships with an empty `codes/` catalog (`.gitkeep` only). Users bring their own MATLAB scripts in their fork or clone.
- No automated MATLAB execution or optical numerical validation in this release.

[1.1.0]: https://github.com/IvanGomezMartinez/MatStudyLab/releases/tag/v1.1.0
[1.0.0]: https://github.com/IvanGomezMartinez/MatStudyLab/releases/tag/v1.0.0
