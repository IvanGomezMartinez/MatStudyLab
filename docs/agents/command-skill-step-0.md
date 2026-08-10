# Command skill Step 0 — Bootstrap (mandatory)

Copy this block as **Step 0** at the top of every MatStudyLab workflow command skill (`accept`, `explain`, `build`, `new`, `modify`).

```markdown
## Step 0 — Bootstrap (mandatory)

Read and execute `.agents/skills/matstudylab-bootstrap/SKILL.md` before any other step.
Do not proceed until bootstrap completes (skip, setup/update, or warn-and-continue).

**Completion criterion:** bootstrap outcome identified (skip, setup/update OK, or warn-and-continue).
```

Implementation detail lives in `.agents/skills/matstudylab-bootstrap/SKILL.md` and `scripts/bootstrap-skills.sh`.
