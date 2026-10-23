---
name: issue-run
description: Unattended work on the repo's GitHub issues, for a scheduled run nobody watches. `check` (by day) reads the open issues and asks every needed question on the issue itself; `build` (after midnight) builds the Ready issues and opens the pull request. Use it when a scheduled task says /issue-run, or the user asks for a check of the issues by hand.
---

# Issue run

Decided by Balázs on 2026-10-22: the issues are the to-do list, and scheduled runs work on them while nobody is in
the chat. A run follows the repo's CLAUDE.md in everything, except that nobody answers in the chat: **every question
goes on the issue as a comment**, never into the final message only. "Before writing code, ask" is met by the
question on the issue; "Ready" is the user's OK to build without a chat.

Mode is the argument: `check` or `build`. Without one, `check`.

## What a run may take

- **Ready** issues (the user approved them) and **In progress** ones a run started earlier (its comment says so).
- **Blocked** issues whose last comment is the user's, answering the question (the user replied).
- Never Backlog, never an issue whose title starts with ⏸️, never Review or Done. A **Ready** issue whose title
  starts with ⏸️ is on hold, not approved work: set it to **Backlog** with a comment naming the trigger (the user
  sets it back to Ready when the time comes). Anything not Ready is the user's signal to look.
- Never anything on the repo CLAUDE.md's "Ask before" list (schema changes, `--remote` commands, DNS, Microsoft 365,
  credentials, new outside services or libraries, release folders...), however clear it looks: post the question,
  set Blocked.
- Skip the whole repo when a chat session is mid-work: an open round in `notes/crew/`, or a commit on the work
  branch in the last hour that no run made. Say so in the final message.

## Check (by day, no code)

1. Read the open issues (ground truth, or the GitHub tools) and, for each issue a run may take, its comments.
2. For each one, decide: can it be built from what is written, with no guess? If not, post **all** the questions at
   once, each as a short multiple choice with a recommendation, in the user's plain language (CLAUDE.md, "How to
   explain things"), and set it to **Blocked**.
3. An issue that turns out to be on hold (it waits for something else): say what it waits for in a comment, put ⏸️
   and the trigger at the start of the title, set it to **Backlog**.
4. A Blocked issue the user answered completely: comment "Thanks, building tonight." and leave it Blocked (the build
   picks it up). Answered only in part: ask the rest.
5. Write nothing to the repo. No commit, no push.

## Build (after midnight)

1. Run the check steps first, so nothing unclear gets built.
2. Bring the work branch up to date with `main` (merge, never rebase). Check the pull request from the work branch:
   if the last one was merged, the next commits need a new one.
3. Take at most 3 issues per repo per night, Blocked-and-answered first, then Ready, oldest first. For each:
   - Set it to **In progress** and comment "Started by the night run."
   - Build it. Run every check in the repo CLAUDE.md's "Before saying a change is done" that runs here (no Revit,
     no remote database). A check that cannot run here is named in the pull request as untested.
   - A check fails and the fix is not clear: undo this issue's changes, comment what failed, set **Blocked**.
   - Commit (stage only the paths changed) and push to the work branch.
4. One pull request work branch → `main` (pr-body skill). First run `/code-review` on the diff against `main` and
   fix what it finds (a finding left as is gets a line in the description saying why). Open it, or add to the open
   one; its description says "Closes #<n>" for each issue built. Subscribe to its activity, so failing checks and
   review comments are handled. Set those issues to **Review**. Never merge.
5. Update `notes/handoff.md` (Waiting for the user: the pull request to test and merge) and push.

## Final message

The run's last message is what the notification shows. Start it with **"Needs you:"** followed by one line per
pull request to test and per question asked, each with its link, or with **"Nothing for you."** when there is
neither. Then, per repo, one line on what was looked at.
