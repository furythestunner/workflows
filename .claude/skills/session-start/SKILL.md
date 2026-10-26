---
name: session-start
description: Start-of-session brief. Runs the ground-truth script (stale facts, repos, worktrees, open PRs + CI, open issues by status, background jobs), reads notes/handoff.md and reconciles it against those facts, checks deadlines, then proposes the task of the day from the handoff, the GitHub issues and questions.md. Use it at the start of every session, right after /clear, or whenever the user asks where things stand ("where are we", "what's next", "continue the work", "what's running", "resume", "start the day", "what did we do last time").
---

# Session start

Rebuild just enough context to pick the day's work, from the files and the machine alone: the last session's
conversation is gone. CLAUDE.md and the memory index are already loaded, so don't read them again.

The inverse of `/handoff`. Don't just execute the top item: tracker statuses drift in both directions (items still
open that already shipped, "done" items whose code changed since).

## Steps

1. **Ground truth first:** `bash .claude/skills/session-start/ground-truth.sh` (facts past their check-by date,
   repos and their worktrees against the remote, LOCAL ONLY and uncommitted work, branches no worktree holds, open
   PRs with a CI verdict, open issues by status label, background jobs; what it looks at is in
   `.claude/ground-truth.conf`). Exit 2 means a probe failed: that section is UNKNOWN, never "clean" or "no
   issues". An open PR is usually the active thread.
2. **Read `notes/handoff.md`**: Next, Waiting for the user, Running, Last session.
   - If it is missing, or older than the latest activity in git or on GitHub, say so, and build the brief from
     the issues, `questions.md` and the ground truth instead.
   - `notes/handoff-archive.md` holds the earlier handoffs: never read it whole; search it when the handoff or a
     question points there.
   - Beyond the Next list, open work is in the GitHub issues (the ground truth lists them by status; `BACKLOG.md`
     only links there) and the user's open questions in `questions.md` §1. Read them when the Next list is done or
     the user asks for something else. `questions.md` §2 holds rulings and deliberate
     non-fixes: never propose "fixing" one of those.
3. **Reconcile the handoff against the ground truth** (the step everyone skips). The handoff is a claim; check each
   claim the brief will repeat:
   - "merged", "pushed", "nothing uncommitted" → the repo sections. A LOCAL ONLY commit or an uncommitted worktree
     the handoff does not mention goes in the brief: work that exists only on this disk.
   - **Each item in "Running"** → the background section. If it finished, read the last lines of its log and note
     the outcome: done, failed, timed out. Analyze results only once the user picks that task.
   - **Failing CI** (`CI RED`) → `gh pr checks <n> -R <owner/repo>` for the failing job.
   - **Today's date and time** against deadlines (expiries, scheduled jobs, events). Anything due within a day goes
     first.
   - Before proposing an issue, re-confirm it in the code: is it still broken or missing? If it is done already,
     say so and comment on the issue that it can be closed (or close it, if the user says so by number). A fix you *depend on*:
     spot-check that it still holds.
   - **STALE FACTS** → say each one first in the brief, and re-check it before anything relies on it. A fact the user
     confirmed (`verified by <name>, <date>`) wins over one Claude worked out; a re-checked fact gets a new date.
   - **NEEDS A LABEL** → name the issue in the brief. A missing type, or a missing status on an issue nobody has
     approved, Claude may fix (`Status: Backlog`); anything else waits for the user.
   - **Open pull requests or issues when the script says UNKNOWN for them:** list them with the GitHub tools
     instead (the repos in `.claude/ground-truth.conf`). The script reads GitHub through `gh api` (REST); on a PC
     it needs the GitHub CLI (`winget install --id GitHub.cli`, then `gh auth login`).
   - **Expected, not news:** the work branch (`WORK_BRANCH` in `.claude/ground-truth.conf`) ahead of `main` while a
     round waits for the user to test and merge; leftover `claude/*` or `ccr-*` branches on GitHub from earlier cloud
     sessions.
   - **Is the work branch up to date with `main`?** If `main` has commits the work branch lacks, merging `main` in
     comes before new work (CLAUDE.md, Git workflow).
4. **Brief the user** in under about 20 lines:
   - **Stale facts** first, if any: what each says and that it is re-checked before use.
   - **Since last session:** what finished or changed (jobs, CI, merged PRs), contradictions first.
   - **Today:** at most 3 items, time-sensitive first. Each with its repo or area, its verified current state, one
     line on why now, and what "done" looks like. Default order when the user has no preference: work in flight,
     bugs users hit, decided-but-not-done (🟢), then deferred work. Only `Status: Ready` issues (the user approved
     them), `Status: In progress` ones, or a Backlog issue the user hands out in the chat are started; any other
     `Status: Backlog` issue is proposed for the user to approve.
     Items in different repos or areas can run side by side (one session or worktree each). An item
     marked ⚠ cross-repo runs alone, in its order (producer first, then each consumer).
   - **Waiting for you:** the `questions.md` §1 items that block today's work, each with a recommendation, named by
     what the user sees (a screen's title, a command), not by a code name. These are never self-serve. Also the
     `Status: Review` issues to test and merge, and the `Status: Blocked` ones, each with the link to its question.
   - **Your skills:** from `.claude/skills/CHEATSHEET.md` (the hook prints it), one short line per skill: the
     command and when to use it, a few words each. In the 3-line brief before a specific task, one line naming them.
   - End by recommending one task and asking which to start.
5. **Wait for the user's choice** before long work or anything outward (push, PR, merge, release, comments,
   messages). Reading and checking are fine. The user decides the day's priorities, and the handoff can be stale.
6. **Rename the chat once the topic is clear.** A chat started with this command is named after it, so the list of
   chats shows only "session start". As soon as the user has picked the task (or the work has clearly settled on
   one), give the chat a short title that says what it is about: the area plus the task, 3 to 7 words, no dates,
   no em dashes (e.g. "Type Cleaner: Write and undo test"). Rename again if the session moves to a different topic.
   - Cloud session (claude.ai/code): `set_session_title` (claude-code-remote tools); the session id comes from
     `get_session` with no arguments.
   - No rename tool in this session (local desktop or CLI): suggest the title to the user in one line, so they can
     rename the chat themselves. Do not claim it was renamed.

## Notes

- The brief is for a person: plain sentences, no internal IDs unless they help (PR numbers, paths, unit names do).
- If the ground truth contradicts the handoff (a job that failed, a branch never pushed), put it first and fix the
  handoff's claim when the session ends.
- Work started after the brief is recorded at the end of the session with `/handoff`.
