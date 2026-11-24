# What changed, in plain words

One line per change that reaches the project repos with the sync, newest first. The sync pull request in each repo
shows the lines added since that repo's last sync, grouped by their start (`scripts/changes-since.sh`):

- `New:` something the user or Claude can now do.
- `Fixed:` something that went wrong before.
- `For you:` something the user does or sees differently (a step, a habit, a screen).

Write what the user notices, not the file names. Lines are never edited later: a correction is a new line.

- 2026-11-24 For you: Each feature now gets its own branch and its own pull request, so features no longer mix and parallel sessions stop clashing. Run each desktop session in its own worktree (the worktree option when you start a session in the Code tab). The work branch keeps only the handoff and notes.
- 2026-11-24 New: Every ruling Claude writes into `questions.md` gets one line on why you decided it. A later session then does not reopen it. If Claude does not know the why, it asks you.
- 2026-11-24 New: When a pull request adds or changes a feature, Claude also updates that feature's part of the README: what it does for you and which files hold it.
- 2026-11-23 Fixed: Claude can no longer push new work onto the work branch after you merged its pull request without opening a new pull request in the same step. Before, that work sat unseen behind the merged pull request (intranet, twice). Notes and handoff updates still go through as before.
- 2026-11-23 For you: Pull request descriptions start with "✅ Safe to merge" or "⛔ Waits for you" and why. Then: what changes, what you need to do, and what happens if it is wrong. The test results and review notes are folded at the bottom (one click opens them).
- 2026-11-19 Fixed: When Claude tries to open a pull request without a review, the message now points to the right rule ("Pull requests" in the session rules). Before, it named a heading that does not exist.
- 2026-11-19 New: Claude Code refuses the usual commands for some actions that cannot be undone: reading secret files (`.env`, keys), force push, `git reset --hard` and `git clean`. Nobody can approve them in a session. A command written another way can still slip past: a guard against mistakes, not a lock.
- 2026-11-19 New: When an explanation still does not land the second time, Claude shows it as a diagram or a small web page.
- 2026-11-19 New: A shorter sentence keeps every condition and every "may", so a short answer never turns a guess into a fact.
- 2026-11-19 Fixed: The rules every session loads are a little shorter. Lines that only repeated what a hook says when it fires are gone.
- 2026-11-19 New: Claude writes in simple language in every repo: short sentences of about 20 words, active voice, one name per thing, common words. It was a trial in the workflows repo since 10 Nov.
- 2026-11-19 New: Asked for a YouTube transcript in a cloud session, Claude says at once that YouTube blocks it. It still finds the title and looks for other sources.
- 2026-11-10 For you: Issues have three statuses now: Backlog, Ready, In progress. A question from Claude comes as a comment and the issue goes back to Backlog: answer it, then set the issue to Ready again. An issue stays In progress until its pull request is merged. Blocked, Review and Done are gone.
- 2026-11-10 For you: An off switch. If a workflow update ever breaks the sessions of a repo: on GitHub, in that repo's work branch, Add file, Create new file, name it `.claude/workflow-off`, Commit changes. A new session then runs without the hooks and says so. Delete the file to turn them back on.
- 2026-11-10 For you: If you use sessions with several repos: paste `cloud/setup-script.sh` into the cloud environment's Setup script once more, so the off switch works there too.
- 2026-11-10 For you: Shared lessons no longer travel by themselves. A lesson that holds in every repo still goes under "Shared" in the repo's `notes/lessons.md`; say "collect the shared lessons" in a workflows session to bring them to every repo. The check that sorted lessons after a reply is gone.
- 2026-11-10 New: `notes/usage.md` counts how often each hook fires and each skill is used, so later cuts go by a count. It is saved with the handoff.
- 2026-11-10 New: Narrow facts (SharePoint upload limit, the Windows PCs, GitHub's free plan and so on) moved out of the text every session loads into a file Claude reads only when the topic comes up. Sessions start with about 45 lines less.
- 2026-11-10 Fixed: Less repeated text and fewer extra turns. Gone: the skill hint on every message, the skills list at session start, the round timer (it made an extra commit after every code reply; a round takes 1 to 15 min, and the rules now say so) and "building" merge mode, which no repo used.
- 2026-11-10 New: When Claude says your setup "already has" or "has no" something without opening a file, a check sends it back to look, cite the file and correct itself.
- 2026-11-10 For you: The brief is back at the top of the first reply in a session, and short (about 8 lines): what is wrong or due, what Claude does next, your open steps (one 🟡 line each) and one proposed task. The answer comes below it, after a line.
- 2026-11-08 New: `/grill-me` also asks about the odd cases of a feature (nothing there yet, errors, very long or very many entries, people without rights, month and year ends), each with a recommended answer.
- 2026-11-08 New: `/plain` can walk you through how an existing page or feature works, from your side. Ask "how does X work?" or "walk me through X".
- 2026-11-08 New: The "Workflow update" pull request in each repo opens with what is new, what is fixed and what changes for you, from this list.
