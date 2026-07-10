# Contributing to MatStudyLab

Thank you for improving the template. This repo is the **structure, docs, and agent skills** — not a shared catalog of laboratory MATLAB code.

## Before you start

1. Read [docs/spec.md](docs/spec.md) for the workflow contract.
2. Read [docs/development_guide.md](docs/development_guide.md) for validation and seams.
3. Do **not** commit proprietary lab scripts, patient data, or personal `LORE.md` content.

## Local setup

```bash
git clone https://github.com/IvanGomezMartinez/MatStudyLab.git
cd MatStudyLab
cp docs/templates/LORE.md LORE.md   # local only — file is gitignored
```

Open the folder in Cursor (or another AI-enabled editor) to exercise the command skills under `.agents/skills/`.

## Making changes

1. Create a branch from `main`.
2. Keep changes focused on template behaviour, docs, or skills — not personal catalog content under `codes/`.
3. Run the QA suite from the repository root:

```bash
./scripts/qa.sh
```

4. Open a pull request with a short summary of **what** changed and **why**.

## What we validate

`./scripts/qa.sh` checks command skill structure, bootstrap behaviour, per-command script seams, and the synthetic E2E pipeline. It does **not** run MATLAB or assert optical numerical correctness.

## Pull request checklist

- [ ] `./scripts/qa.sh` passes locally
- [ ] User-facing docs updated when behaviour changes (`README.md`, `docs/spec.md`, or skills)
- [ ] `CHANGELOG.md` updated under `[Unreleased]` for user-visible changes (maintainers fold into a release tag)
- [ ] No proprietary `.m` files, measurement data, or `LORE.md` in the diff

## Questions

Open a [GitHub issue](https://github.com/IvanGomezMartinez/MatStudyLab/issues) for bugs in the workflow template or documentation gaps.
