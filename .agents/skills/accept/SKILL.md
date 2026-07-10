---
name: accept
description: "Promote staging bundles into the catalog, or attach explain docs from explain/."
disable-model-invocation: true
---

The only allowed write path into `codes/`. Two modes: **promote** (`new/` / `modify/`) or **attach** (`explain/` → catalog).

Read `LORE.md` (if present), `docs/spec.md` (`/accept` requirements), and `CONTEXT.md` before acting.

## Step 0 — Bootstrap (mandatory)

Read and execute `.agents/skills/matstudylab-bootstrap/SKILL.md` before any other step.
Do not proceed until bootstrap completes (sync, skip, or failed-with-continue).

**Completion criterion:** bootstrap outcome identified (fresh, synced, or failed-with-continue).

## Step 1 — Parse variant

| User input | Scope |
|------------|-------|
| `/accept`, `/accept all` | All pending bundles in `new/` and `modify/` |
| `/accept new` | Only `new/` |
| `/accept modify` | Only `modify/` |
| `/accept explain` | Copy `explain/explain_<stem>.md` into matching `codes/<type>/<bundle>/` |
| `/accept explain <type> <bundle>` | One catalog bundle only |

**Completion criterion:** variant is identified.

If variant is `all` (or default) **and** both `new/` and `modify/` have pending bundles, ask: accept everything, only `new/`, or only `modify/`?

## Step 2 — Read LORE

Read `LORE.md` for git workflow (`local-only` or `own-repo`) and folder map context.

If `LORE.md` is missing, assume `local-only` and note it to the user.

**Completion criterion:** git workflow preference is known.

## Step 3 — List and validate scope

### Promote (`all` / `new` / `modify`)

```bash
ACCEPT_DRY_RUN=1 ./scripts/accept-bundle.sh <variant>
```

Validation rules:

- At least one `.m` — otherwise **block**
- At least one base companion `.md` (not `explain_*.md`) — otherwise **block** and offer to generate from `docs/templates/script-companion.md`
- **1:1:** one `.m` + one `.md` with matching stems
- **N:1:** multiple `.m` + exactly one base `.md`

Promotion also attaches matching `explain/explain_<stem>.md` files into the catalog bundle.

### Attach (`explain`)

```bash
ACCEPT_DRY_RUN=1 ./scripts/accept-bundle.sh explain [type bundle]
```

For each `explain/explain_<stem>.md`:

- Resolve `codes/<type>/<bundle>/` from path (`explain/<type>/<bundle>/…`) or by unique `codes/*/*/<stem>.m`
- **Block** if catalog bundle or matching `.m` is missing
- Copy into catalog

**Completion criterion:** every item in scope passes validation or the command stops with a clear block reason.

## Step 4 — Confirm destination

Confirm ambiguous `codes/<type>/<bundle>/` paths with the user. New `codes/<type>/` folders require user confirmation and a LORE folder-map row.

**Completion criterion:** user confirmed each destination path.

## Step 5 — Execute

```bash
./scripts/accept-bundle.sh <variant> [type bundle]
```

After a successful run, clear staging for everything accepted:

- **`new/` / `modify/`** — remove the promoted bundle folder (empty parent dirs too)
- **`explain/`** — remove each attached `explain_<stem>.md` (empty parent dirs too)

**Completion criterion:** each item exists under `codes/`; no accepted files remain in `new/`, `modify/`, or `explain/` for this run.

## Step 6 — Git per LORE

| Git workflow | Action |
|--------------|--------|
| `local-only` | Do not commit or push |
| `own-repo` | Propose commit message `catalog: <type>/<bundle>` after user OK; then ask about push to `main` |

**Completion criterion:** git behavior matches LORE.

## Step 7 — LORE updates (significant changes only)

Append to `LORE.md` **only** when this accept introduced something that changes future behaviour — for example a new `codes/<type>/` folder, a reclassification, or a confirmed preference about units, equipment, or workflow.

Routine promote/attach (moving drafts or study docs into an existing bundle) does **not** warrant a decision-log entry. **Do not ask** the user about LORE unless a significant change occurred in this run.

**Completion criterion:** LORE updated when warranted; otherwise proceed without mentioning the decision log.

## Safety (non-negotiable)

- Never write to `codes/` except through this confirmed flow.
- Never delete measurement data files.
- From `new/`: block if `codes/<type>/<bundle>/` already exists (use `/modify` instead).

## Reference

- Wayfinder spec: `.scratch/matstudylab/issues/08-grilling-comando-accept.md`
- Companion template: `docs/templates/script-companion.md`
- Step 0 contract: `docs/agents/command-skill-step-0.md`
