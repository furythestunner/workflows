---
name: pr-body
description: The shape of a pull request description: what changes for the users, evidence that it works, and the merge danger (one-way or two-way door, blast radius). Use whenever you write or update a pull request description, or the user asks how risky a merge is.
---

# Pull request description

Adapted from mattpocock/skills (`pr`, MIT, see `../THIRD-PARTY.md`).

The reader merges it, and may not read code. Write for what people see and do. Skip preambles.

## Template

```markdown
<If the pull request changes the database or needs a manual step after the merge, say so here, first, in bold.>

## What changes
- <for whom, on which page or tool, in plain words; one line each>

## Evidence
- **Before:** <what happened before: screenshot, number, test result>
  **After:** <what happens now>
- Checks run: <the project's checks from CLAUDE.md, each with its result>

## Merge danger
**Door:** <one-way or two-way>: <one line why>
**Blast radius:** <one or two words>: <who or what could break if it is wrong>
**If it goes wrong:** <how to undo it: revert the pull request, restore the database, re-run an import ...>

## How to test
1. <numbered steps the reader follows on the test branch>
```

## Merge danger

- A **two-way door** can be walked back: revert the pull request and everything is as before (page layout, a new
  button, a wording change).
- A **one-way door** cannot be undone by a revert: database changes, data rewritten or deleted, e-mails sent to
  people, files published, a changed export others already downloaded. Say what the way back is (a backup, a
  database restore) and how long it stays available.
- The **blast radius** is who or what is hit if it is wrong: one page, everyone's numbers, the month-end PDFs,
  billing, sign-in. Think it through before writing "small".
- If the project merges to publish (the merge is the deploy), say so in the merge danger line.
