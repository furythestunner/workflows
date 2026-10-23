# Workflow master copy

This repo is the master copy of the Claude Code session workflow (README.md says what each file does). Every change
to the workflow is made here first, then copied to Kol-Lab-Design-Kft/intranet, KolLab.extension and website,
adjusted to each project. It runs the workflow on itself too.

## Who you are talking to

Balázs, a BIM coordinator (Revit, IFC, Dynamo, ACC); not a software developer. Plain words, the answer first, one
action per step.

## How to explain things

Name what Balázs sees (a command, a file, a GitHub page), not internal code names. Concrete times ("about 15 min").
No em dashes.

## Before saying a change is done

- `bash scripts/check.sh` prints no FAIL (CI runs the same on every pull request).
- A hook change: start a new cloud session on dev-test; the first reply must open with the brief.
- The rules block below changed: change the block in README.md the same way (`scripts/check.sh` compares them).

## Ask before

Merging, closing issues, changing a scheduled task, anything in the project repos.

## This repo only

- No `.claude/workflow-version` here: this repo is the version. The project repos name a commit of `main` in theirs,
  and the weekly drift check (`scripts/drift-check.sh`) reports the ones behind.
- Rulings on the workflow itself are in README.md, "Rules of this setup"; `questions.md` §2 points there.

<!-- The block below is README.md's "CLAUDE.md block" with dev-test and Balázs filled in. Change both together. -->
## Sessions and trackers

- **Session start and handoff are automatic** (hooks in `.claude/settings.json`). At every start,
  `.claude/hooks/session-start.sh` moves a cloud session to `dev-test`, runs
  `.claude/skills/session-start/ground-truth.sh` (configured in `.claude/ground-truth.conf`) and loads the handoff;
  the first reply opens with the brief (`/session-start` steps 2 to 5). After every reply,
  `.claude/hooks/handoff-check.sh` sends Claude back to update and push `notes/handoff.md` when pushed code on
  `dev-test` is newer than it. The handoff is a claim, the script is the fact: a contradiction is reported first.
- **The handoff is short:** `notes/handoff.md` holds only Next (in order), Waiting for the user and Unfinished (work
  that is on one disk only, or committed but not merged). No diary: git has it. This overrides the template in the
  `/handoff` skill.
- **Decisions go into the trackers in the same reply:** a ruling to `questions.md` §2, new open work to a GitHub
  issue, a rule for Claude to this file, a lesson to `notes/lessons.md`; never only into the chat.
- **Trackers:** open work is the repo's GitHub issues (`BACKLOG.md` only links there). Each issue has one `Type:`
  label (Feature, Bug, Config, Docs) and one `Status:` label (Backlog, Ready, In progress, Blocked, Review, Done).
  Ready means Balázs approved it; an open issue in any other status is for Balázs to look at, or for later. Only
  Balázs moves an issue to Ready or Done and closes issues, on GitHub; Claude gives the link. Claude opens new issues
  in Backlog and may move: Ready → In progress; a Backlog issue Balázs hands out in the chat → In progress (the chat
  is the approval); any → Blocked (after posting the question on the issue, never guessing); any → Backlog when it
  turns out to be on hold (a comment says what it waits for, the title starts with ⏸️ and names the trigger); In
  progress → Review (only with an open pull request that says "Closes #<n>"; merging it closes the issue).
  `.claude/hooks/issue-guard.mjs` blocks the rest, even when asked in the chat. Rulings stay in `questions.md`.
- **Unattended runs:** scheduled sessions follow `/issue-run` (`check` by day, `build` after midnight). They work
  only on Ready issues and on Blocked ones Balázs has answered; every question goes on the issue, never into a chat
  nobody reads. A run never merges.
- **Every pull request gets a review and a watcher:** before opening one, run `/code-review` on the diff against
  `main` and fix what it finds; a finding left as is gets a line in the pull request saying why. Right after opening
  it, subscribe to its activity (auto-fix; needs the Claude GitHub App on the repo), so failing checks and review
  comments are handled until it is merged or closed.
- **Facts expire:** a fact that can go stale (a version, an IP address, a price, who owns what, a menu path) goes in
  `notes/lessons.md`, never in a memory, and ends in exactly `(check by YYYY-MM-DD)`: 3 months ahead by default,
  never more than 12. One Balázs confirmed reads `(verified by Balázs, YYYY-MM-DD)`, gets 12 months and wins over
  one Claude worked out. The brief lists due facts first, under STALE FACTS; re-check them before relying on them.
- **Corrected twice becomes a hook:** if Balázs corrects the same behaviour twice, propose a hook that blocks it,
  with a recommendation. A rule written only as prose is not enough. The first correction goes under "Hook
  candidates" in `notes/lessons.md`, so the second one is noticed.
- **Handoff rule:** `/handoff` and the end-of-reply check commit and push the docs (handoff, trackers, `notes/`) to
  `dev-test` without asking.
- **Time estimates are real session time:** size Claude's own work in minutes of actual session time, not a
  human developer's hours or days, and give Balázs's part (clicks, merges, a token to create) separately.
- **Point out a skill that fits:** when a request fits a skill in `.claude/skills/CHEATSHEET.md` that the user did
  not call, say so in one line ("Tip: `/grill-me` fits this") and carry on with the request.
- **Crew rounds (`/crew`):** the session is the orchestrator (brief, the user's OK, review, commit); a Haiku `scout`
  reads and a Sonnet `implementer` writes (`.claude/agents/`). The model of each role is the user's call. An open
  round's brief and status are in `notes/crew/`: read it at session start.
- The setup comes from github.com/furythestunner/workflows (`.claude/workflow-version` names the commit). Project
  values go only in `.claude/ground-truth.conf`, never in the scripts.
- **Workflow changes start in the master copy:** any change to the workflow (hooks, skills, agents, the cheat
  sheet, these session rules) is made in github.com/furythestunner/workflows first, then copied to every repo that
  uses it, adjusted to the project. A workflow to-do is an issue in the master copy, never one in a project repo.
<!-- End of the README.md block. Rules for this repo only go above it, under "This repo only". -->
