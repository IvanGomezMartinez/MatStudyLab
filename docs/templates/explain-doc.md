# Deep study doc (`explain_<stem>.md`) template

Use for `/explain` output in `explain/`. Does **not** replace the base companion `<stem>.md`.

**Language:** per `LORE.md` companion language preference.

---

## Blank template

```markdown
# Study: <Human-readable title>

> Script: `<path/to/script.m>`  
> Generated: YYYY-MM-DD

## Summary

What this script does in plain language for an optical lab technician.

## Possible improvements (not implemented)

Ideas to make the script clearer, faster, or more robust — **do not change the `.m` file** in this command.

- …

## MATLAB concepts

Plain-language notes on MATLAB ideas used here (arrays, FFT, indexing, …).

## Your questions

(Answers when the user provided a hint with `/explain <script> <question>`.)

- …

## Catalog handoff

When ready, run `/accept` to attach this file to the bundle in `codes/<type>/<bundle>/`.
```
