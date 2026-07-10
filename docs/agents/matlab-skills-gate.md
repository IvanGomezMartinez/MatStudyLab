# MATLAB skills gate (mandatory for `/new` and `/modify`)

Read and apply **both** vendored MATLAB skills before writing or revising any `.m` file:

| Skill | Path | Role |
|-------|------|------|
| **matlab** | `.agents/skills/matlab/SKILL.md` | Syntax, scripts, matrices, graphics, best practices |
| **matlab-performance-optimizer** | `.agents/skills/matlab-performance-optimizer/SKILL.md` | Vectorization, memory, profiling when performance matters |

These skills are **installed manually** in `.agents/skills/` (bootstrap auto-sync deferred). If either file is missing, stop and tell the user to install them before generating or editing code.

**Completion criterion:** both skill files were read and their guidance applied to the script or changes.

## Deferred

Auto-sync of MATLAB skills via `skills-lock.json` / bootstrap — out of scope for now; skills stay manually vendored.
