<!-- Synced from github.com/furythestunner/workflows. Do not edit it in a project repo: change it in the master copy,
     and the sync pull request brings it here. This repo's own rules go in its CLAUDE.md. -->
# Session workflow (shared by every repo)

These rules come from the master copy and are the same in every repo. The work branch is `WORK_BRANCH` and the
user is `USER_NAME` in `.claude/ground-truth.conf`.

**This repo's CLAUDE.md adds to these rules; it never replaces them.** It holds what is specific to this project
(stack, checks, hard rules, extra "ask before" items). If a line there seems to contradict a rule here, follow this
file, say so to the user, and propose either a change in the master copy or a fix to CLAUDE.md.

## Sessions and trackers

- **Session start and handoff are automatic** (hooks in `.claude/settings.json`). At every start,
  `.claude/hooks/session-start.sh` moves a cloud session to the work branch, runs
  `.claude/skills/session-start/ground-truth.sh` (configured in `.claude/ground-truth.conf`) and loads the handoff;
  the first reply opens with the brief (`/session-start` steps 2 to 5). After every reply,
  `.claude/hooks/handoff-check.sh` sends Claude back to update and push `notes/handoff.md` when pushed code on
  the work branch is newer than it. The handoff is a claim, the script is the fact: a contradiction is reported first.
- **The handoff is short:** `notes/handoff.md` holds only Next (in order), Waiting for the user and Unfinished (work
  that is on one disk only, or committed but not merged). No diary: git has it. This overrides the template in the
  `/handoff` skill.
- **Decisions go into the trackers in the same reply:** a ruling to `questions.md` §2, new open work to a GitHub
  issue, a rule for Claude to this file, a lesson to `notes/lessons.md`; never only into the chat.
- **Trackers:** open work is the repo's GitHub issues (`BACKLOG.md` only links there). Each issue has one `Type:`
  label (Feature, Bug, Config, Docs) and one `Status:` label (Backlog, Ready, In progress, Blocked, Review, Done).
  Ready means the user approved it; an open issue in any other status is for the user to look at, or for later. Only
  the user moves an issue to Ready or Done and closes issues, on GitHub; Claude gives the link. Claude opens new issues
  in Backlog and may move: Ready → In progress; a Backlog issue the user hands out in the chat → In progress (the chat
  is the approval); any → Blocked (after posting the question on the issue, never guessing); any → Backlog when it
  turns out to be on hold (a comment says what it waits for, the title starts with ⏸️ and names the trigger); In
  progress → Review (only with an open pull request that says "Closes #<n>"; merging it closes the issue).
  `.claude/hooks/issue-guard.mjs` blocks the rest, even when asked in the chat. Rulings stay in `questions.md`.
- **Unattended runs:** scheduled sessions follow `/issue-run` (`check` by day, `build` after midnight). They work
  only on Ready issues and on Blocked ones the user has answered; every question goes on the issue, never into a chat
  nobody reads. A run never merges.
- **Every pull request gets a review and a watcher:** before opening one, run `/code-review` on the diff against
  `main` and fix what it finds; a finding left as is gets a line in the pull request saying why. Right after opening
  it, subscribe to its activity (auto-fix; needs the Claude GitHub App on the repo), so failing checks and review
  comments are handled until it is merged or closed.
- **Facts expire:** a fact that can go stale (a version, an IP address, a price, who owns what, a menu path) goes in
  `notes/lessons.md`, never in a memory, and ends in exactly `(check by YYYY-MM-DD)`: 3 months ahead by default,
  never more than 12. One the user confirmed reads `(verified by the user, YYYY-MM-DD)`, gets 12 months and wins over
  one Claude worked out. The brief lists due facts first, under STALE FACTS; re-check them before relying on them.
- **Corrected twice becomes a hook:** if the user corrects the same behaviour twice, propose a hook that blocks it,
  with a recommendation (`/never-again`). A rule written only as prose is not enough. The first correction goes
  under "Hook candidates" in `notes/lessons.md`, so the second one is noticed.
- **Handoff rule:** `/handoff` and the end-of-reply check commit and push the docs (handoff, trackers, `notes/`) to
  the work branch without asking.
- **One work branch, named branches only:** all work goes on `WORK_BRANCH`, never on the cloud session's own
  `claude/...` branch and never on `main`. A second branch only when parallel work really needs one (the user asks
  for it, or a round on the work branch must not mix with this one), named `WORK_BRANCH-<topic>`: the topic in 1 to
  4 lowercase words joined by hyphens (`app-test-leave-totals` for a work branch `app-test`). The sync's own
  `workflow-sync` is the only other name. Say in the chat when one is made, list it in the handoff's Unfinished
  until its pull request is merged, and then ask the user to click "Delete branch" on the merged pull request (a
  cloud session cannot delete branches). `.claude/hooks/branch-guard.mjs` blocks creating or pushing any other name.
- **Time estimates are real session time:** size Claude's own work in minutes of actual session time, not a
  human developer's hours or days, and give the user's part (clicks, merges, a token to create) separately.
- **Use the skill that fits:** when a request fits a skill in `.claude/skills/CHEATSHEET.md` that the user did not
  call, use it and say so in one line ("Used `/plain` for this"). `.claude/hooks/skill-nudge.mjs` names the likely
  skill on every message; a review on a pull request always goes through `/verify`.
- **Crew rounds (`/crew`):** the session is the orchestrator (brief, the user's OK, review, commit); a Haiku `scout`
  reads and a Sonnet `implementer` writes (`.claude/agents/`). The model of each role is the user's call. An open
  round's brief and status are in `notes/crew/`: read it at session start.
- **The setup comes from github.com/furythestunner/workflows** (`.claude/workflow-version` names the commit). Project
  values go only in `.claude/ground-truth.conf`, never in the scripts.
- **Workflow changes start in the master copy:** any change to the workflow (hooks, skills, agents, the cheat
  sheets, these rules) is made in github.com/furythestunner/workflows. A sync pull request then brings it to every
  repo; the user merges it. Never edit a synced file in a project repo (`.claude/workflow-manifest` lists them): the
  next sync undoes the edit. A workflow to-do is an issue in the master copy, never one in a project repo.
- **A project's own skills** go in `.claude/skills/<name>/` under a name the master copy does not use, with one line
  in `.claude/skills/CHEATSHEET.project.md` (same shape as `CHEATSHEET.md`). The sync never touches them.
