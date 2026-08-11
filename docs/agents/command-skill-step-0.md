# Command skill Step 0 — Bootstrap (mandatory)

Copy this block as **Step 0** at the top of every MatStudyLab workflow command skill (`accept`, `explain`, `build`, `new`, `modify`).

```markdown
## Step 0 — Bootstrap (mandatory)

Read and execute `.agents/skills/matstudylab-bootstrap/SKILL.md` before any other step.
Do not proceed until bootstrap completes (skip, setup/update, or warn-and-continue).

**Completion criterion:** bootstrap outcome identified (skip, setup/update OK, or warn-and-continue).
```

## Orchestrator v2 (what Step 0 runs)

Implementation lives in `.agents/skills/matstudylab-bootstrap/SKILL.md` and `scripts/bootstrap-skills.sh`:

- **Branches:** `setup` (incomplete/missing catalog) or `update` (stale sync); skip when fresh or `local-only`.
- **Node gate:** sync needs Node/`npx`; without it, non-`/build` commands warn and continue on vendored skills; `/build` opens HITL.
- **Preference:** gitignored tooling pref (`mode` + `last_synced_at`); schema example at [docs/templates/skills-pref.example.json](../templates/skills-pref.example.json). Freshness is **not** stored in `skills-lock.json`.
- **Catalog:** setup installs the full Pocock set plus both MATLAB skills; update refreshes all lock origins. Owned command skills stay out of the lock and are name-guarded.
