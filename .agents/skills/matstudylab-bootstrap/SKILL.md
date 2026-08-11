---
name: matstudylab-bootstrap
description: "Check-on-use skills setup/update before workflow commands — not user-facing."
disable-model-invocation: true
---

Runs automatically as **Step 0** of `/accept`, `/explain`, `/build`, `/new`, and `/modify`. End users never invoke this skill directly. Not a user-facing slash command; harness-agnostic (no Cursor-only rule).

English is the default for all agent UX strings here. Localize only when `LORE.md` or a `/build` language choice says so.

## Step 1 — Run bootstrap script

From the repository root, run:

```bash
./scripts/bootstrap-skills.sh
```

The script chooses the branch (`setup` vs `update` vs skip). Do not pick the branch yourself.

**Completion criterion:** the script finished and you captured its stdout/stderr (including any `bootstrap:` lines and exit status).

## Step 2 — Interpret outcome

Match every `bootstrap:` line the script printed. Outcomes (in addition to a final `bootstrap: OK` on success paths):

| Output line | Meaning | Parent-command action |
|-------------|---------|------------------------|
| `bootstrap: SKIPPED_LOCAL_ONLY` | Preference `mode` is `local-only` — no Node/network | Proceed (vendored skills). `/build` may still offer HITL to re-enable sync — see Step 3. |
| `bootstrap: SKIPPED_FRESH` | `last_synced_at` within 24h — no sync needed | Proceed |
| `bootstrap: NODE_MISSING` | Node/`npx` not available | See Step 3 (warn+continue vs `/build` HITL) |
| `bootstrap: WOULD_SETUP` | Dry-run only (`BOOTSTRAP_DRY_RUN=1`); would run setup | Tests only — do not use in production |
| `bootstrap: WOULD_UPDATE` | Dry-run only; would run update | Tests only — do not use in production |
| `bootstrap: SETUP_OK` | First-time / incomplete catalog install succeeded | Proceed |
| `bootstrap: UPDATE_OK` | Stale catalog update succeeded | Proceed |
| `bootstrap: SYNC_FAILED_CONTINUE` | Setup or update failed (network, auth, or CLI) | See Step 3 (warn+continue vs `/build` HITL) |
| `bootstrap: NAME_GUARD_FAIL` | Owned skill name collision; script exits **non-zero** | **Stop.** Do not continue the parent command until the collision is fixed |
| `bootstrap: OK` | Terminal success marker (printed after most branches) | Required on exit 0; alone does not identify the branch |

On `SYNC_FAILED_CONTINUE` / `NODE_MISSING`, the script still exits 0 after `bootstrap: OK` — treat those as warnings for non-`/build` commands, not hard stops. `NAME_GUARD_FAIL` is the hard stop (exit ≠ 0).

**Completion criterion:** you named exactly which outcome branch ran (including `NAME_GUARD_FAIL` if exit ≠ 0) and know whether Step 3 requires a user warning or `/build` HITL.

## Step 3 — Parent-command policy

### `/new`, `/modify`, `/accept`, `/explain`

On `NODE_MISSING` or `SYNC_FAILED_CONTINUE`, **warn the user in English** (default) and continue with vendored skills in `.agents/skills/`:

- **Node missing:**
  ```text
  Warning: Node/`npx` missing — could not check for skill updates.
  Using vendored `.agents/skills/`. (Use /build to open setup or set local-only.)
  Continuing with the command…
  ```
- **Sync failed:**
  ```text
  Warning: skills sync failed; using vendored `.agents/skills/`.
  Continuing with the command…
  ```

Do not open a HITL menu on these commands.

### `/build`

Do **not** use the warn+continue strings above. After this skill finishes, `/build` **must** run its own **Step 1 — Skills HITL** in `.agents/skills/build/SKILL.md`:

- `SKIPPED_LOCAL_ONLY` → short notice + optional re-enable (`auto`)
- `NODE_MISSING`, `SYNC_FAILED_CONTINUE`, or incomplete setup → three-option menu (continue session / save `local-only` / open setup)
- Quiet success (`SETUP_OK` / `UPDATE_OK` / `SKIPPED_FRESH`) → one-line notice, no menu; ensure `mode: auto` after setup/update OK (`last_synced_at` stamped by the script)

**Completion criterion:** for non-`/build` parents, any required English warning was shown (or no warn was needed); for `/build`, bootstrap outcome is captured so Step 1 HITL can run (or quiet success continues); `NAME_GUARD_FAIL` never continues.

## Step 4 — Continue workflow

Proceed with the parent command only after Steps 1–3. Do not re-run bootstrap in this session unless the user explicitly asks or `/build` HITL triggers another setup/update.

**Completion criterion:** bootstrap is complete; parent command may start its next step.

## Reference

### Setup vs update (script decides)

- **Setup** — catalog missing / incomplete: adds full Pocock catalog plus `matlab` and `matlab-performance-optimizer` (copy into `.agents/skills/`).
- **Update** — lock present and previously synced OK but stale: project-scoped `npx skills@latest update -p -y` (never pass a repo id as update positional).
- Owned project skills (`matstudylab-bootstrap`, `accept`, `build`, `new`, `modify`, `explain`) are name-guarded and not updated by the catalog CLI.

### Preference sidecar

Path: `.matstudylab/skills-pref.json` (gitignored; absence ⇒ `auto` and never synced).

```json
{ "mode": "auto" | "local-only", "last_synced_at": "<ISO-8601 or null>" }
```

- Freshness uses **`last_synced_at`** (24h), **not** a lockfile `last_checked` field.
- `mode: local-only` → `SKIPPED_LOCAL_ONLY` (no Node/network probe).
- Successful setup/update stamps `last_synced_at`.

### Pointers

- Step 0 contract for new command skills: `docs/agents/command-skill-step-0.md`
- Spec: `docs/spec.md` — Skills layout
- Canonical English HITL copy: `.scratch/skills-auto-provisioning-v2/assets/prototype-node-gate-messages.md`
- OS install checklists: `docs/agents/skills-node-os-checklist.md`
- Manual HITL verification: `docs/agents/build-skills-hitl-checklist.md`
