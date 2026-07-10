# MatStudyLab

Structured MATLAB workspace for **optical lab technicians** — optometrists and imaging specialists who need reliable scripts and want to learn programming along the way.

Use AI-assisted commands to **create**, **modify**, **catalog**, **import**, and **understand** MATLAB code for real laboratory work (MTF, PSF, IOL profiles, Zernike, and more). Every script ships with a companion `.md` that explains *why* it exists, *how* to run it, and *what optical context* it assumes.

> **Template repository** — this repo provides folder structure, conventions, and AI workflow skills. It does **not** include proprietary laboratory MATLAB code. Your scripts live in **your** fork or clone, under your control.

## Who is this for?

- Optical laboratory technicians with strong optics/imaging background
- Optometrists working with image-quality metrics
- Anyone with limited programming experience who wants readable, educational MATLAB

## Repository layout

```
MatStudyLab/
├── LORE.md                         # Your lab context, units, equipment, preferences
├── import/                         # Dump existing scripts (any subfolders) → /build
├── codes/<type>/<bundle>/          # Stable catalog — source of truth
│   ├── script.m
│   ├── script.md                   # Base companion
│   └── explain_script.md           # Deep study doc (optional, from /explain)
├── new/<type>/<bundle>/            # Drafts from /new (not yet cataloged)
├── modify/<type>/<bundle>/         # Edits in progress from /modify
└── explain/                        # Scripts to study without changing (/explain)
```

**Type folders** (`mtf/`, `psf/`, `iol-profiles/`, `zernikes/`, …) group scripts by optical magnitude. **Bundles** are subfolders holding one or more `.m` files plus their companion `.md`.

See [docs/spec.md](docs/spec.md) for the full contract.

## AI workflow

| Command    | Purpose |
|------------|---------|
| `/build`   | Scan `import/`, propose bundles, catalog incrementally into `codes/<type>/<bundle>/` |
| `/new`     | Create a new script + base `.md` in `new/` after guided checklist |
| `/modify`  | Copy from `codes/` to `modify/`, adapt with guided flow (never edits catalog in place) |
| `/accept`  | Promote bundles from `new/` or `modify/` into `codes/`; `/accept explain` attaches study docs from `explain/` |
| `/explain` | Deep-dive `explain_<stem>.md` — no `.m` changes |

Commands are implemented as user-invoked agent skills under `.agents/skills/` (see [development guide](docs/development_guide.md)).

**Safety:** the AI never edits `codes/` in place. All writes go through `new/`, `modify/`, or confirmed `/build` moves.

## Quick start

1. **Fork or clone** this repository.
2. Open the folder in **Cursor** (or your preferred AI-enabled editor).
3. Copy [docs/templates/LORE.md](docs/templates/LORE.md) to `LORE.md` and fill in your lab context.
4. Dump existing scripts into `import/` and run `/build`, or use `/new` for fresh scripts.
5. Study scripts with `/explain`; promote work with `/accept`.

MATLAB R20xx or later is recommended. Required toolboxes depend on each script and are listed in its companion `.md`.

## Documentation

- [Implementation spec](docs/spec.md) — commands, folders, safety rules
- [Development guide](docs/development_guide.md) — contributor workflow
- [MATLAB guidelines](docs/matlab-guidelines.md) — coding baseline
- [Domain glossary](CONTEXT.md) — project vocabulary

## What is *not* in this repo

- Proprietary laboratory measurement scripts
- Patient or client data
- Vendor-specific calibration files

Add those only in your private copy.

## License

[MIT](LICENSE) — free to use, modify, and distribute the **template** (structure, docs, skills). Your own `codes/` content remains yours; you are responsible for what you commit to your fork.

## Author

[Ivan Gómez Martínez](https://github.com/IvanGomezMartinez) — optical technologies & imaging.
