# MATLAB skills gate (mandatory for `/new` and `/modify`)

Read and apply **both** vendored MATLAB skills before writing or revising any `.m` file:

| Skill | Path | Role |
|-------|------|------|
| **matlab** | `.agents/skills/matlab/SKILL.md` | Syntax, scripts, matrices, graphics, best practices |
| **matlab-performance-optimizer** | `.agents/skills/matlab-performance-optimizer/SKILL.md` | Vectorization, memory, profiling when performance matters |

Bootstrap (`matstudylab-bootstrap` Step 0) **does** sync both skills with the rest of the lockfile catalog (setup/update when Node is available). That does **not** replace reading them: for `/new` and `/modify` you must still open both `SKILL.md` files and apply their guidance.

If either file is missing after bootstrap, stop and tell the user to restore the vendor tree (or run setup via `/build`) before generating or editing code.

**Completion criterion:** both skill files were read and their guidance applied to the script or changes.
