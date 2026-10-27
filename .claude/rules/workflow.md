<!-- Synced from github.com/furythestunner/workflows. Do not edit it in a project repo: change it in the master copy,
     and the sync pull request brings it here. This repo's own rules go in its CLAUDE.md. -->
# Session workflow (shared by every repo)

Same in every repo, from the master copy. The work branch is `WORK_BRANCH` and the user is `USER_NAME` in
`.claude/ground-truth.conf`. **This repo's CLAUDE.md adds to these rules, never replaces them** (stack, checks, hard
rules, extra "ask before" items). If a line there seems to contradict this file, follow this file, tell the user,
and propose a change in the master copy or a fix to CLAUDE.md.

## Sessions and trackers

- **Session start (automatic, hooks in `.claude/settings.json`):** `.claude/hooks/session-start.sh` moves a cloud
  session to the work branch, runs `.claude/skills/session-start/ground-truth.sh` (configured in
  `.claude/ground-truth.conf`) and loads the handoff. The first reply opens with the brief (`/session-start` steps 2
  to 5). The handoff is a claim, the script is the fact: report a contradiction first.
- **Handoff:** `notes/handoff.md` holds only Next (in order), Waiting for the user and Unfinished (work on one disk
  only, or committed but not merged). No diary; this overrides the `/handoff` template. After a reply,
  `.claude/hooks/handoff-check.sh` sends Claude back to update and push it when pushed code on the work branch is
  newer. `/handoff` and that check commit and push the docs (handoff, trackers, `notes/`) to the work branch without
  asking.
- **Decisions go into a tracker in the same reply, never only into the chat:** a ruling to `questions.md` §2, new
  open work to a GitHub issue, a rule for Claude to this file, a lesson to `notes/lessons.md`. A ruling that replaces
  an earlier one edits that entry ("replaced YYYY-MM-DD: ..."), never a second entry beside it.
- **Issues** are the open work (`BACKLOG.md` only links there; rulings stay in `questions.md`). Each has one `Type:`
  label (Feature, Bug, Config, Docs) and one `Status:` label (Backlog, Ready, In progress, Blocked, Review, Done).
  Ready means the user approved it; any other open status is for the user to look at, or for later. Only the user
  moves an issue to Ready or Done, on GitHub (Claude gives the link), and closes it, unless the user's own message
  names it by number ("close #12"). Claude opens issues in Backlog and may move only these
  (`.claude/hooks/issue-guard.mjs` blocks the rest, even when asked in the chat):
  - Ready → In progress; Backlog → In progress when the user hands it out in the chat (the chat is the approval);
  - any → Blocked, after posting the question on the issue (never guess);
  - any → Backlog when on hold: a comment says what it waits for, the title starts with ⏸️ and names the trigger;
  - In progress → Review, only with an open pull request that says "Closes #<n>" (merging it closes the issue), or
    in building mode "Part of #<n>" (the issue stays open until the user has tested it and says to close it).
- **Unattended runs** follow `/issue-run` (`check` by day, `build` after midnight): only Ready issues and Blocked
  ones the user answered; every question goes on the issue; a run never merges and never turns on auto-merge.
- **Pull requests:** before opening one, run `/code-review` on the diff against `main` and fix what it finds (a
  finding left as is gets a line in the pull request saying why). Right after opening it, subscribe to its activity
  (auto-fix; needs the Claude GitHub App on the repo) and handle failing checks and review comments until it is
  merged or closed. A review on a pull request always goes through `/verify`.
- **Merging** (the user's ruling: the chat approval is the merge approval). Work the user approved in the chat, with
  its checks green, merges without asking: turn on auto-merge when opening the pull request (merge commit), or merge
  it once the checks pass if auto-merge cannot be turned on. `MERGE_MODE` in `.claude/ground-truth.conf` (the brief
  shows it) decides which pull requests:
  - `building` (before v1.0, nobody uses `main`): every one; it says "Part of #<n>", not "Closes #<n>", and one
    round's fixes go in one pull request. Moving to v1.0 (`released`) is the user's call in the chat.
  - `released` (the default when the key is missing): only a two-way door (`/pr-body`, "Merge danger"; when unsure,
    it is a one-way door), and nothing this repo's CLAUDE.md lists as always asking. A one-way door waits for the user.
- All work goes on `WORK_BRANCH`: never on the cloud session's `claude/...` branch, never on `main`.
- A second branch only when parallel work really needs it (the user asks, or a round must not mix with the work
  branch), named `WORK_BRANCH-<topic>` with 1 to 4 lowercase words joined by hyphens (`app-test-leave-totals` for
  `app-test`). The only other name is the sync's `workflow-sync`. Say in the chat when one is made, list it in the
  handoff's Unfinished until merged, then ask the user to click "Delete branch" on the merged pull request (a cloud
  session cannot). `.claude/hooks/branch-guard.mjs` blocks creating or pushing any other name.
- **Facts expire:** a fact that can go stale (a version, an IP address, a price, who owns what, a menu path) goes in
  `notes/lessons.md`, never in a memory, ending in exactly `(check by YYYY-MM-DD)`: 3 months ahead by default, 12 at
  most. One the user confirmed reads `(verified by the user, YYYY-MM-DD)`, gets 12 months and wins over one Claude
  worked out. The brief lists due facts first (STALE FACTS); re-check them before relying on them.
- **Project or shared:** a lesson only about this project goes in `notes/lessons.md`; one true in any repo (Claude
  Code, the PCs and tools, working with the user, a first correction) goes under `## Shared (goes to every repo)` at
  its end. A daily job in the master copy collects those into `.claude/rules/shared-lessons.md` (synced, loaded by
  itself); then delete it from the Shared section. In the master copy, write it straight into that file.
  `.claude/hooks/lesson-check.mjs` asks for both after a reply.
- **Corrected twice becomes a hook:** the first correction goes under "Hook candidates" in `notes/lessons.md`; at
  the second, propose a hook that blocks it, with a recommendation (`/never-again`). Prose alone is not enough.
- **Time estimates are measured, not felt:** `.claude/hooks/round-timer.mjs` writes each reply that made a code commit
  to `notes/rounds.md` and has Claude commit it; the brief shows the latest. Size Claude's work from the closest
  round there, never by feel (feel ran 4 to 6 times too high), and give the user's part separately.
- **Use the skill that fits** (`.claude/skills/CHEATSHEET.md`) even when not called, and say so in one line ("Used
  `/plain` for this"). `.claude/hooks/skill-nudge.mjs` names the likely one on every message.
- **Crew rounds:** `/crew` holds the roles, models and steps. At session start, read an open round's brief and
  status in `notes/crew/`.
- **The setup comes from github.com/furythestunner/workflows** (`.claude/workflow-version` names the commit).
  Project values go only in `.claude/ground-truth.conf`, never in the scripts.
- **Workflow changes** (hooks, skills, agents, cheat sheets, these rules) and workflow to-dos (issues) belong in the
  master copy (github.com/furythestunner/workflows) only. A sync pull request brings changes to every repo; the sync
  merges it, except one with steps by hand, which waits for the user. Never edit a synced file in a project repo
  (`.claude/workflow-manifest`): the next sync undoes it. A project's own skills go in `.claude/skills/<name>/` (a
  name the master copy does not use) with one line in `.claude/skills/CHEATSHEET.project.md`; the sync never touches
  them.
