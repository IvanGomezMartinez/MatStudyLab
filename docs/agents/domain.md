# Domain Docs

How the engineering skills should consume this repo's domain documentation.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root
- **`docs/spec.md`** for workflow commands, folders, and safety rules
- **`docs/adr/`** — read ADRs that touch the area (create lazily when decisions are made)

If `CONTEXT.md` does not exist, proceed silently.

## File structure

Single-context repo:

```
/
├── CONTEXT.md
├── AGENTS.md
├── docs/
│   ├── spec.md
│   ├── matlab-guidelines.md
│   └── adr/
└── LORE.md                    # User memory (not domain glossary)
```

## Use the glossary's vocabulary

When naming domain concepts, use terms as defined in `CONTEXT.md`. Do not drift to synonyms listed under _Avoid_.

## LORE vs CONTEXT

- `CONTEXT.md` — project-wide domain language (catalog, bundle, staging, commands).
- `LORE.md` — per-user lab context (equipment, units, personal prefs). Read before any command; overrides style, not safety.
