# Issue tracker: Local Markdown

Issues and PRDs for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The PRD is `.scratch/<feature-slug>/PRD.md`
- Implementation issues are `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`
- Triage state is recorded as a `Status:` line near the top of each issue file (see `docs/agents/triage-labels.md`)
- Comments append under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create or update a file under `.scratch/<feature-slug>/`.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path.

## Wayfinding operations

- **Map**: `.scratch/<effort>/map.md`
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`
- **Blocking**: `Blocked by: NN, NN` line near the top
- **Frontier**: open, unblocked, unclaimed tickets; first by number wins
- **Claim**: set `Status: claimed`
- **Resolve**: append `## Answer`, set `Status: resolved`, update map

## MatStudyLab

- Wayfinder effort: `.scratch/matstudylab/`
- Implementation PRD: `.scratch/matstudylab/PRD.md` (`ready-for-agent`)
- Closed wayfinder tickets: `.scratch/matstudylab/issues/01`–`14`
