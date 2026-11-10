# What changed, in plain words

One line per change that reaches the project repos with the sync, newest first. The sync pull request in each repo
shows the lines added since that repo's last sync, grouped by their start (`scripts/changes-since.sh`):

- `New:` something the user or Claude can now do.
- `Fixed:` something that went wrong before.
- `For you:` something the user does or sees differently (a step, a habit, a screen).

Write what the user notices, not the file names. Lines are never edited later: a correction is a new line.

- 2026-11-10 For you: Issues have three statuses now: Backlog, Ready, In progress. A question from Claude comes as a comment and the issue goes back to Backlog: answer it, then set the issue to Ready again. An issue stays In progress until its pull request is merged. Blocked, Review and Done are gone.
- 2026-11-10 For you: An off switch. If a workflow update ever breaks the sessions of a repo: on GitHub, in that repo's work branch, Add file, Create new file, name it `.claude/workflow-off`, Commit changes. A new session then runs without the hooks and says so. Delete the file to turn them back on.
- 2026-11-10 New: `notes/usage.md` counts how often each hook fires and each skill is used, so later cuts go by a count. It is saved with the handoff.
- 2026-11-10 New: Narrow facts (SharePoint upload limit, the Windows PCs, GitHub's free plan and so on) moved out of the text every session loads into a file Claude reads only when the topic comes up. Sessions start with about 45 lines less.
- 2026-11-10 Fixed: Less repeated text and fewer extra turns. Gone: the skill hint on every message, the skills list at session start, the round timer (it made an extra commit after every code reply; a round takes 1 to 15 min, and the rules now say so) and "building" merge mode, which no repo used.
- 2026-11-10 New: When Claude says your setup "already has" or "has no" something without opening a file, a check sends it back to look, cite the file and correct itself.
- 2026-11-10 For you: The brief is back at the top of the first reply in a session, and short (about 8 lines): what is wrong or due, what Claude does next, your open steps (one 🟡 line each) and one proposed task. The answer comes below it, after a line.
- 2026-11-08 New: `/grill-me` also asks about the odd cases of a feature (nothing there yet, errors, very long or very many entries, people without rights, month and year ends), each with a recommended answer.
- 2026-11-08 New: `/plain` can walk you through how an existing page or feature works, from your side. Ask "how does X work?" or "walk me through X".
- 2026-11-08 New: The "Workflow update" pull request in each repo opens with what is new, what is fixed and what changes for you, from this list.
