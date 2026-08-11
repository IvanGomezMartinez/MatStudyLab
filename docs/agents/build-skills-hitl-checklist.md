# Manual checklist — `/build` skills HITL

Human verification for skills auto-provisioning HITL (not automated chat). English. Prefer preference file `.matstudylab/skills-pref.json` and bootstrap stdout markers.

## Preconditions

- [ ] On a clone with `.agents/skills/build/SKILL.md` and `./scripts/bootstrap-skills.sh`
- [ ] Can set or clear `.matstudylab/skills-pref.json` and (for Node tests) PATH / `BOOTSTRAP_FORCE_NO_NODE=1`

## A — `local-only`

- [ ] Pref `mode: local-only` → bootstrap prints `SKIPPED_LOCAL_ONLY`; `/build` shows short vendored notice + Continue / Re-enable sync
- [ ] No Node probe and no network sync while local-only
- [ ] Re-enable sync writes `mode: auto`, then re-runs bootstrap

## B — Node missing (full menu)

- [ ] With `auto`/absent pref and no `npx` → `NODE_MISSING`; three options match prototype Scenario B
- [ ] Option 1 continues this session without writing `local-only`
- [ ] Option 2 writes `mode: local-only` and continues
- [ ] Option 3 prints **only** the OS block from `docs/agents/skills-node-os-checklist.md` (never auto-installs)

## C — Sync failed

- [ ] Node present but sync fails → `SYNC_FAILED_CONTINUE`; three options (Scenario C), option 3 retries setup/update

## D — Incomplete setup

- [ ] Empty `skills` map and/or `last_synced_at: null` without a fresh `SETUP_OK`/`UPDATE_OK` → Scenario D menu (or B/C when those markers apply)

## E — Setup / update OK

- [ ] After successful setup/update: one-line success; `mode` is `auto`; `last_synced_at` stamped
- [ ] `SKIPPED_FRESH` → quiet one-liner; no menu

## Regression — other commands

- [ ] `/accept` and `/new` (also `/modify`, `/explain`): on `NODE_MISSING` or `SYNC_FAILED_CONTINUE` → English warn + continue only; **no** three-option menu

## References

- Skill: `.agents/skills/build/SKILL.md` (Step 1)
- Bootstrap policy: `.agents/skills/matstudylab-bootstrap/SKILL.md`
- Prototype copy: `.scratch/skills-auto-provisioning-v2/assets/prototype-node-gate-messages.md`
