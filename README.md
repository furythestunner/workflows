# Claude Code session workflow

Automatic session start, a short handoff and a decision check for Claude Code, in every repo.
Started from github.com/truongfelix/workflow (6d2623c, 2026-10-10).

## Why it is copied into each repo

A cloud session (claude.ai/code, the phone app) reads only the repo's own `.claude/settings.json`. Settings in
`~/.claude` on a PC never reach it, and plugins do not load there. So every repo carries its own copy, and this repo
is the master: every workflow change (hooks, skills, agents, the cheat sheet, the CLAUDE.md block) is made here
first, then copied to each repo (intranet, KolLab.extension, website) and adjusted to the project. Workflow to-dos
are the issues of this repo.

## What it does

| File | When | What |
|---|---|---|
| `.claude/hooks/session-start.sh` | every session start | Cloud session: switches to `WORK_BRANCH` and pulls. PC: fast-forwards the checked-out branch when nothing is uncommitted or unpushed, otherwise says why not. Runs `ground-truth.sh`, checks whether the handoff is older than the last code commit, prints the handoff and the skills cheat sheet. Claude's first reply opens with the brief. |
| `cloud/setup-script.sh` | once, in the cloud environment | Pasted into the environment's Setup script (environment menu in the session's title bar, Edit, Setup script). A session with two or more repos opens in the folder that holds them, where no repo's hook runs; this installs a user-level hook that runs each repo's `session-start.sh` from there: one brief per repo, the skills list once. In a one-repo session it does nothing. |
| `.claude/hooks/handoff-check.sh` | after every reply | If pushed code on `WORK_BRANCH` is newer than the handoff, sends Claude back once to update and push it. |
| `.claude/hooks/decision-check.mjs` | after every reply | If the user answered a multiple-choice question or used decision words and no tracker changed (and no issue was opened), asks Claude to record the decision. |
| `.claude/hooks/issue-guard.mjs` | before every Bash or GitHub tool call | Blocks Claude from setting `Status: Ready` or `Status: Done`, from closing an issue, and from opening one outside `Status: Backlog`. `issue-guard.test.sh` next to it tests it (`bash .claude/hooks/issue-guard.test.sh`). |
| `.claude/skills/CHEATSHEET.md` | every session start | One line per skill and hook: what it does, when to use it. The hook prints it and the brief ends with a short "Your skills" list, so they do not get forgotten. Update it with any skill change. |
| `.claude/skills/session-start/` | `/session-start`, and the hook | The brief, and `ground-truth.sh` (stale facts first, branches against GitHub, uncommitted work, open PRs and CI, open issues by status). `labels.sh` creates the issue labels. |
| `.claude/skills/handoff/` | `/handoff` | The full tidy-up at the end of a session. |
| `.claude/skills/crew/`, `.claude/agents/` | `/crew` | A feature round as a crew: this session plans, talks to the user, reviews and commits; a Haiku `scout` reads and a Sonnet `implementer` writes. Checks come from the repo's CLAUDE.md. Round records in `notes/crew/`. |
| `.claude/skills/grill-me/` | `/grill-me`, or before a big change | Interview in rounds, no cap on questions, each with a recommended answer ("yes" accepts it). |
| `.claude/skills/questionnaire/` | `/questionnaire` | Turns open questions (e.g. `questions.md` §1) into a document for one person to fill in; answers go back to the trackers. |
| `.claude/skills/wait-what/` | `/wait-what`, "I don't understand" | Re-explains the last message in plain words, with the missing context. |
| `.claude/skills/pr-body/` | writing a pull request | What changes, evidence, merge danger (one-way or two-way door, blast radius), how to test. |
| `.claude/skills/issue-run/` | a scheduled run | Unattended work on the issues: `check` asks the questions on the issues, `build` builds Ready issues and opens the pull request. |
| `.claude/skills/diagnosing-bugs/` | a bug or wrong number | Builds a check that fails on the bug first, then hypotheses, fix, proof, cleanup. |

The last five are adapted from github.com/mattpocock/skills (MIT, `.claude/skills/THIRD-PARTY.md`).

The scripts hold no project data. Everything project-specific is in `.claude/ground-truth.conf`.

Only in this master copy (not copied to the repos):

| File | When | What |
|---|---|---|
| `scripts/check.sh` | every pull request (`.github/workflows/check.yml`), and before a push | Every script parses, `settings.json` is valid and its hook files exist, the issue guard's tests pass, the cheat sheet lists every skill. |
| `scripts/drift-check.sh` | Mondays 07:43 Budapest, scheduled task "Workflow drift check" | Compares each repo's `.claude/workflow-version` with `main` here and lists the workflow commits it is missing. The task opens or updates one Backlog issue here when a repo is behind. |

## Add it to a repo

1. Copy `.claude/` from here into the repo root (keep any `.claude/agents/` or other skills the repo already has;
   merge `settings.json` by hand if the repo has one).
2. Edit `.claude/ground-truth.conf`: `REPOS`, `WORK_BRANCH`, `HANDOFF`, `DOCS`, `USER_NAME`.
3. Create `notes/handoff.md`, `questions.md` (§1 open questions, §2 rulings), `notes/lessons.md` (with a
   `## Hook candidates` heading), `notes/crew/log.md` (its starting table is at the end of
   `.claude/skills/crew/SKILL.md`) and a `BACKLOG.md` that holds only the link to the repo's issues
   (`https://github.com/<owner>/<repo>/issues`).
4. Create the labels: `bash .claude/skills/session-start/labels.sh` (every GitHub repo in the config).
5. An existing `BACKLOG.md`: one issue per item, `Status: Backlog`, the section it sat in as its `Type:` label
   (pick the closest of feature, bug, config, docs) and the item's text as the body. Then cut the file down to the
   link. Every fact that can go stale, in `notes/lessons.md` or in a memory, gets a `(check by YYYY-MM-DD)` tag
   and lives in `notes/lessons.md` (delete the memory).
6. Add the block below to the repo's `CLAUDE.md` (replace `<work branch>` and `<user>`).
7. Write the commit of this repo into `.claude/workflow-version`, commit, push to the work branch.
8. Once per cloud environment (not per repo): paste `cloud/setup-script.sh` into its Setup script, so sessions
   with several repos get the brief too.
9. Check: start a new cloud session; the first reply must open with the brief, and the brief must list the issues
   by status. `bash .claude/hooks/issue-guard.test.sh` must print no FAIL.

Needs `bash`, `git` and `node` (cloud sessions have them; on Windows, Git Bash).

## CLAUDE.md block

```markdown
## Sessions and trackers

- **Session start and handoff are automatic** (hooks in `.claude/settings.json`). At every start,
  `.claude/hooks/session-start.sh` moves a cloud session to `<work branch>`, runs
  `.claude/skills/session-start/ground-truth.sh` (configured in `.claude/ground-truth.conf`) and loads the handoff;
  the first reply opens with the brief (`/session-start` steps 2 to 5). After every reply,
  `.claude/hooks/handoff-check.sh` sends Claude back to update and push `notes/handoff.md` when pushed code on
  `<work branch>` is newer than it. The handoff is a claim, the script is the fact: a contradiction is reported first.
- **The handoff is short:** `notes/handoff.md` holds only Next (in order), Waiting for the user and Unfinished (work
  that is on one disk only, or committed but not merged). No diary: git has it. This overrides the template in the
  `/handoff` skill.
- **Decisions go into the trackers in the same reply:** a ruling to `questions.md` §2, new open work to a GitHub
  issue, a rule for Claude to this file, a lesson to `notes/lessons.md`; never only into the chat.
- **Trackers:** open work is the repo's GitHub issues (`BACKLOG.md` only links there). Each issue has one `Type:`
  label (Feature, Bug, Config, Docs) and one `Status:` label (Backlog, Ready, In progress, Blocked, Review, Done).
  Ready means <user> approved it; an open issue in any other status is for <user> to look at, or for later. Only
  <user> moves an issue to Ready or Done and closes issues, on GitHub; Claude gives the link. Claude opens new issues
  in Backlog and may move: Ready → In progress; a Backlog issue <user> hands out in the chat → In progress (the chat
  is the approval); any → Blocked (after posting the question on the issue, never guessing); any → Backlog when it
  turns out to be on hold (a comment says what it waits for, the title starts with ⏸️ and names the trigger); In
  progress → Review (only with an open pull request that says "Closes #<n>"; merging it closes the issue).
  `.claude/hooks/issue-guard.mjs` blocks the rest, even when asked in the chat. Rulings stay in `questions.md`.
- **Unattended runs:** scheduled sessions follow `/issue-run` (`check` by day, `build` after midnight). They work
  only on Ready issues and on Blocked ones <user> has answered; every question goes on the issue, never into a chat
  nobody reads. A run never merges.
- **Every pull request gets a review and a watcher:** before opening one, run `/code-review` on the diff against
  `main` and fix what it finds; a finding left as is gets a line in the pull request saying why. Right after opening
  it, subscribe to its activity (auto-fix; needs the Claude GitHub App on the repo), so failing checks and review
  comments are handled until it is merged or closed.
- **Facts expire:** a fact that can go stale (a version, an IP address, a price, who owns what, a menu path) goes in
  `notes/lessons.md`, never in a memory, and ends in exactly `(check by YYYY-MM-DD)`: 3 months ahead by default,
  never more than 12. One <user> confirmed reads `(verified by <user>, YYYY-MM-DD)`, gets 12 months and wins over
  one Claude worked out. The brief lists due facts first, under STALE FACTS; re-check them before relying on them.
- **Corrected twice becomes a hook:** if <user> corrects the same behaviour twice, propose a hook that blocks it,
  with a recommendation. A rule written only as prose is not enough. The first correction goes under "Hook
  candidates" in `notes/lessons.md`, so the second one is noticed.
- **Handoff rule:** `/handoff` and the end-of-reply check commit and push the docs (handoff, trackers, `notes/`) to
  `<work branch>` without asking.
- **Time estimates are real session time:** size Claude's own work in minutes of actual session time, not a
  human developer's hours or days, and give <user>'s part (clicks, merges, a token to create) separately.
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
```

## Rules of this setup

Decided by Balázs on 2026-10-22, from an r/ClaudeCode post ("runs like a small engineering team"); GitHub stays, no
GitLab.

- Open work lives in GitHub issues. `BACKLOG.md` keeps only the link, so there is one list.
- `questions.md` stays a file: a ruling is a standing rule, not a task, and a closed issue drops out of sight.
- The check-by tag has one fixed form, `(check by YYYY-MM-DD)`, so the script can read it; other spellings are
  listed as BAD TAG.
- Facts that can go stale live only in `notes/lessons.md`: memories stay on one PC, and a cloud session cannot see
  their dates. Default 3 months, at most 12; a fact the user confirmed also expires, after 12 months.
- The user moves issues to Ready or Done by clicking on GitHub (website or phone app). The guard has no "unlock"
  phrase: a phrase could be copied from a document or an issue comment. Moving down (to Backlog or Blocked) needs
  no approval, so Claude may do it (Balázs, 22 Oct 2026): anything not in Ready is then the user's signal to look.
- Labels read as plain words, "Status: Ready", "Type: Bug" (Balázs, 22 Oct 2026; until then `status::ready`).
  `labels.sh` renames the old ones, so every issue keeps its status.
- Scheduled runs (Balázs, 22 Oct 2026): a day check every 4 hours asks its questions on the issues, a night build
  after midnight Budapest time builds the approved ones and opens the pull request; a phone notification only
  when something needs the user.
- Done = closed: the pull request says "Closes #<n>" and merging it is the approval. `Status: Done` is for work with
  no pull request (a server or a setting).
- Claude may open issues, always in backlog. An issue with a missing or double label is listed as NEEDS A LABEL,
  never guessed into a status.
- Issues are not shared outside the repo's collaborators for now (the repos are private).
- Decided by Balázs on 2026-10-23: this repo runs the workflow on itself (its own `CLAUDE.md`, handoff and
  trackers); `scripts/check.sh` runs on every pull request; every pull request gets `/code-review` before it opens
  and a watcher after; a weekly drift check (Mondays 07:43 Budapest, phone notification) reports repos on an old
  copy.
- Skills live only in the repos, never uploaded to a claude.ai account (Balázs, 2026-10-23): he works on a personal
  and a company account and does not want to install them on each, and only the repo copy reaches every session.
- Plugins stay out: plugins a repo's `.claude/settings.json` declares do not load in cloud sessions (Claude Code
  docs, "Settings in cloud sessions"), so the files are copied into each repo.
