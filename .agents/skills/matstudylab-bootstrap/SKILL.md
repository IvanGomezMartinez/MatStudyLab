---
name: matstudylab-bootstrap
description: "Check-on-use skills sync before workflow commands — not user-facing."
disable-model-invocation: true
---

Runs automatically as **Step 0** of `/accept`, `/explain`, `/build`, `/new`, and `/modify`. End users never invoke this skill directly.

## Step 1 — Run bootstrap script

From the repository root, run:

```bash
./scripts/bootstrap-skills.sh
```

**Completion criterion:** the script prints `bootstrap: OK` and exits with status 0.

## Step 2 — Interpret outcome

| Output line | Meaning | Action |
|-------------|---------|--------|
| `bootstrap: SKIPPED_FRESH` | `skills-lock.json` checked within the last 24 hours | Proceed to the workflow command |
| `bootstrap: SYNC_OK` | Lockfile was stale; `npx skills@latest update -p -y` succeeded | Proceed to the workflow command |
| `bootstrap: WOULD_SYNC` | Dry-run only (`BOOTSTRAP_DRY_RUN=1`) | Tests only — do not use in production |
| `bootstrap: SYNC_FAILED_CONTINUE` | Sync failed (network, auth, or CLI missing) | **Warn the user**; proceed with vendored skills already in `.agents/skills/` |

When sync fails, the script still exits 0 after printing `bootstrap: OK` — treat `SYNC_FAILED_CONTINUE` as a warning, not a hard stop.

**Completion criterion:** you have identified which branch ran and told the user when sync failed.

## Step 3 — Continue workflow

Proceed with the parent command only after Step 2.

**Completion criterion:** bootstrap is complete; no further sync attempts in this session unless the user explicitly asks.

## Reference

- Lockfile: `skills-lock.json` (`last_checked` ISO timestamp, updated every run)
- Staleness threshold: **24 hours** (see `scripts/lib/skills_bootstrap.py`)
- Upstream catalog skills sync via `npx skills@latest update`; project command skills (`matstudylab-bootstrap`, `accept`, `build`, `new`, `modify`, `explain`) are **not** updated by that command
- `matlab` and `matlab-performance-optimizer` are listed in the lockfile for inventory but **bootstrap does not sync them** — install manually (see `docs/agents/matlab-skills-gate.md`)
- Step 0 contract for new command skills: `docs/agents/command-skill-step-0.md`
- Spec: `docs/spec.md` — Skills layout, T2
