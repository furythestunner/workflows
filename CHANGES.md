# What changed, in plain words

One line per change that reaches the project repos with the sync, newest first. The sync pull request in each repo
shows the lines added since that repo's last sync, grouped by their start (`scripts/changes-since.sh`):

- `New:` something the user or Claude can now do.
- `Fixed:` something that went wrong before.
- `For you:` something the user does or sees differently (a step, a habit, a screen).

Write what the user notices, not the file names. Lines are never edited later: a correction is a new line.

- 2026-11-08 New: `/grill-me` also asks about the odd cases of a feature (nothing there yet, errors, very long or very many entries, people without rights, month and year ends), each with a recommended answer.
- 2026-11-08 New: `/plain` can walk you through how an existing page or feature works, from your side. Ask "how does X work?" or "walk me through X".
- 2026-11-08 New: the "Workflow update" pull request in each repo opens with what is new, what is fixed and what changes for you, from this list.
