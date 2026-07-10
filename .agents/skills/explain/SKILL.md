---
name: explain
description: "Deep-study a MATLAB script and write explain_<stem>.md without changing .m files."
disable-model-invocation: true
---

Produce `explain_<stem>.md` in `explain/` for one script per session. **Read-only on `.m` files** — never edit `codes/`, `new/`, `modify/`, or `import/` in place.

Read `LORE.md`, `AGENTS.md`, `docs/spec.md`, and `CONTEXT.md` before acting. Use `docs/templates/explain-doc.md` for structure.

## Step 0 — Bootstrap (mandatory)

Read and execute `.agents/skills/matstudylab-bootstrap/SKILL.md` before any other step.
Do not proceed until bootstrap completes (sync, skip, or failed-with-continue).

**Completion criterion:** bootstrap outcome identified (fresh, synced, or failed-with-continue).

## Step 1 — Parse invocation

| User input | Behavior |
|------------|----------|
| `/explain` | Resolve a single `.m` under `explain/`, or list choices if several |
| `/explain <script.m>` | Study that script (paths under `explain/`, `codes/`, `new/`, `modify/`) |
| `/explain <script.m> <question>` | Same + answer the question in **Your questions** |

**No grill-me** — didactic, one-way mode.

**Completion criterion:** target script path is identified.

Helper:

```bash
./scripts/explain-resolve.sh list
./scripts/explain-resolve.sh resolve <hint>
```

## Step 2 — Read context

Read `LORE.md` for companion language and lab context. Read the target `.m` and its base companion `.md` when present (`codes/` is read-only context).

Apply **zoom-out** when the script is long, has non-obvious dependencies or toolboxes, or the user gave a hint — read related files under the same bundle before writing.

**Completion criterion:** script purpose and optical context are understood.

## Step 3 — Write explain doc (explain/ only)

Resolve output path:

```bash
./scripts/explain-resolve.sh resolve <hint>
```

Scaffold if needed, then fill content in the user's language:

```bash
./scripts/explain-resolve.sh scaffold <hint> "<optional question>"
```

Required sections (see `docs/templates/explain-doc.md`):

- **Possible improvements (not implemented)** — ideas only, no code changes
- **MATLAB concepts** — plain-language teaching
- **Your questions** — when the user provided a hint

**Completion criterion:** `explain_<stem>.md` exists under `explain/` with all required sections; no `.m` file was modified.

## Step 4 — Recommend `/accept explain`

If a matching bundle exists in `codes/<type>/<bundle>/`, recommend:

```text
/accept explain
```

or `/accept explain <type> <bundle>` when scope should be one bundle. This copies `explain_<stem>.md` into the catalog (see `.agents/skills/accept/SKILL.md`).

If the script has no catalog bundle yet, suggest `/build` or `/new` first, then `/accept` for the staging bundle.

**Completion criterion:** user knows the next command to attach the study doc.

## Safety (non-negotiable)

- Write **only** under `explain/`.
- Never modify `.m` files.
- Never edit `codes/` in situ.

## Reference

- Wayfinder spec: `.scratch/matstudylab/issues/09-grilling-comando-explain.md`
- Explain template: `docs/templates/explain-doc.md`
- Handoff: use `.agents/skills/handoff/SKILL.md` to compact context before generating the doc when zoom-out applies
