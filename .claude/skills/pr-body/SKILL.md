---
name: pr-body
description: The shape of a pull request description: a first line that says whether it is safe to merge, what changes for the users, what the user needs to do, what happens if it is wrong, and the technical checks folded at the bottom. Use whenever you write or update a pull request description, or the user asks how risky a merge is.
metadata:
  short: "Pull request description: safe to merge or not, what changes, what you do."
  run-by: claude
---

# Pull request description

Adapted from mattpocock/skills (`pr`, MIT, see `../THIRD-PARTY.md`).

The reader merges it and does not read code. The first line answers "can I merge this?"; everything above the fold
is about what people see and do. No preambles, no code words above the fold (no "migration", "door", "blast
radius", "dry run").

## Template

```markdown
✅ **Safe to merge.** <a few words why: "Revert" undoes it; what stays behind after a revert, if anything>
<or>
⛔ **Waits for USER_NAME.** <what a revert cannot undo: the database change, the e-mails already sent ...>

<Only if it changes the database or needs a step by hand, in plain words: "Changes the database: adds the task
'paternity leave'." Never a migration number or file name.>

## What changes
<written with /plain (shape `pr`)>
- <for whom, on which page or tool, what they will notice; one line each>

## What you need to do
- 🟡 <each step click by click: testing on the test branch, a step after the merge>
<or "Nothing.">

## If something is wrong
- **Who notices:** <who or what is hit: one page, everyone's numbers, the month-end PDFs, sign-in>
- **How to undo:** <the "Revert" button on this page; or which backup or restore, and how long it is kept>

<details><summary>Technical checks (for Claude)</summary>

- Before / after: <screenshot, number or test result, before and after>
- Checks run: <the project's checks from CLAUDE.md, each with its result>
- Code review: <findings fixed; each finding left as is, with why>

</details>

Closes #<n>
```

`USER_NAME` is in `.claude/ground-truth.conf`. Keep "Closes #<n>" (or "Part of #<n>") outside the fold, on its own
last line.

## Safe to merge or not

This decides the first line. Claude's own words for it (never in the description): a two-way or a one-way door.

- **✅ Safe to merge** (two-way door): "Revert" puts everything back as before: page layout, a new button, a wording
  change, a new list entry nothing else depends on (say that it stays behind).
- **⛔ Waits for the user** (one-way door): a revert does not undo it: data rewritten or deleted, e-mails sent to
  people, files published, an export others already downloaded. "How to undo" names the way back (a backup, a
  database restore) and how long it stays available. When unsure, it waits.
- **Who notices** needs thought before writing "only one page": whose numbers, which PDFs, billing, sign-in.
- If the merge publishes (the merge is the deploy), the first line says so: "✅ Safe to merge. Goes live on merge;
  'Revert' takes it back."
- The first line decides the merge (`.claude/rules/workflow.md`, Merging): ✅ merges by itself once the checks pass,
  ⛔ waits for the user.
- A pull request that replaces something an earlier one built says so under "What changes" ("Replaces #<n>'s ...").
