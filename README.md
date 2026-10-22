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
| `.claude/hooks/handoff-check.sh` | after every reply | If pushed code on `WORK_BRANCH` is newer than the handoff, sends Claude back once to update and push it. |
| `.claude/hooks/decision-check.mjs` | after every reply | If the user answered a multiple-choice question or used decision words and no tracker changed (and no issue was opened), asks Claude to record the decision. |
| `.claude/hooks/issue-guard.mjs` | before every Bash or GitHub tool call | Blocks Claude from setting `status::ready` or `status::done`, from closing an issue, and from opening one outside `status::backlog`. `issue-guard.test.sh` next to it tests it (`bash .claude/hooks/issue-guard.test.sh`). |
| `.claude/skills/CHEATSHEET.md` | every session start | One line per skill and hook: what it does, when to use it. The hook prints it and the brief ends with a short "Your skills" list, so they do not get forgotten. Update it with any skill change. |
| `.claude/skills/session-start/` | `/session-start`, and the hook | The brief, and `ground-truth.sh` (stale facts first, branches against GitHub, uncommitted work, open PRs and CI, open issues by status). `labels.sh` creates the issue labels. |
| `.claude/skills/handoff/` | `/handoff` | The full tidy-up at the end of a session. |
| `.claude/skills/crew/`, `.claude/agents/` | `/crew` | A feature round as a crew: this session plans, talks to the user, reviews and commits; a Haiku `scout` reads and a Sonnet `implementer` writes. Checks come from the repo's CLAUDE.md. Round records in `notes/crew/`. |
| `.claude/skills/grill-me/` | `/grill-me`, or before a big change | Interview in rounds, no cap on questions, each with a recommended answer ("yes" accepts it). |
| `.claude/skills/questionnaire/` | `/questionnaire` | Turns open questions (e.g. `questions.md` §1) into a document for one person to fill in; answers go back to the trackers. |
| `.claude/skills/wait-what/` | `/wait-what`, "I don't understand" | Re-explains the last message in plain words, with the missing context. |
| `.claude/skills/pr-body/` | writing a pull request | What changes, evidence, merge danger (one-way or two-way door, blast radius), how to test. |
| `.claude/skills/diagnosing-bugs/` | a bug or wrong number | Builds a check that fails on the bug first, then hypotheses, fix, proof, cleanup. |

The last five are adapted from github.com/mattpocock/skills (MIT, `.claude/skills/THIRD-PARTY.md`).

The scripts hold no project data. Everything project-specific is in `.claude/ground-truth.conf`.

## Add it to a repo

1. Copy `.claude/` from here into the repo root (keep any `.claude/agents/` or other skills the repo already has;
   merge `settings.json` by hand if the repo has one).
2. Edit `.claude/ground-truth.conf`: `REPOS`, `WORK_BRANCH`, `HANDOFF`, `DOCS`, `USER_NAME`.
3. Create `notes/handoff.md`, `questions.md` (§1 open questions, §2 rulings), `notes/lessons.md` (with a
   `## Hook candidates` heading), `notes/crew/log.md` (its starting table is at the end of
   `.claude/skills/crew/SKILL.md`) and a `BACKLOG.md` that holds only the link to the repo's issues
   (`https://github.com/<owner>/<repo>/issues`).
4. Create the labels: `bash .claude/skills/session-start/labels.sh` (every GitHub repo in the config).
5. An existing `BACKLOG.md`: one issue per item, `status::backlog`, the section it sat in as its `type::` label
   (pick the closest of feature, bug, config, docs) and the item's text as the body. Then cut the file down to the
   link. Every fact that can go stale, in `notes/lessons.md` or in a memory, gets a `(check by YYYY-MM-DD)` tag
   and lives in `notes/lessons.md` (delete the memory).
6. Add the block below to the repo's `CLAUDE.md` (replace `<work branch>` and `<user>`).
7. Write the commit of this repo into `.claude/workflow-version`, commit, push to the work branch.
8. Check: start a new cloud session; the first reply must open with the brief, and the brief must list the issues
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
- **Trackers:** open work is the repo's GitHub issues (`BACKLOG.md` only links there). Each issue has one `type::`
  label (feature, bug, config, docs) and one `status::` label (backlog, ready, in-progress, blocked, review, done).
  Only <user> moves backlog → ready and review → done, and closes issues, on GitHub; Claude gives the link. Claude
  opens new issues in backlog, may move ready → in-progress, any → blocked (after posting the question on the issue,
  never guessing) and in-progress → review (only with an open pull request that says "Closes #<n>"; merging it
  closes the issue). `.claude/hooks/issue-guard.mjs` blocks the rest, even when asked in the chat. Rulings stay in
  `questions.md`.
- **Facts expire:** a fact that can go stale (a version, an IP address, a price, who owns what, a menu path) goes in
  `notes/lessons.md`, never in a memory, and ends in exactly `(check by YYYY-MM-DD)`: 3 months ahead by default,
  never more than 12. One <user> confirmed reads `(verified by <user>, YYYY-MM-DD)`, gets 12 months and wins over
  one Claude worked out. The brief lists due facts first, under STALE FACTS; re-check them before relying on them.
- **Corrected twice becomes a hook:** if <user> corrects the same behaviour twice, propose a hook that blocks it,
  with a recommendation. A rule written only as prose is not enough. The first correction goes under "Hook
  candidates" in `notes/lessons.md`, so the second one is noticed.
- **Handoff rule:** `/handoff` and the end-of-reply check commit and push the docs (handoff, trackers, `notes/`) to
  `<work branch>` without asking.
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
- The user moves issues to ready or done by clicking on GitHub (website or phone app). The guard has no "unlock"
  phrase: a phrase could be copied from a document or an issue comment.
- Done = closed: the pull request says "Closes #<n>" and merging it is the approval. `status::done` is for work with
  no pull request (a server or a setting).
- Claude may open issues, always in backlog. An issue with a missing or double label is listed as NEEDS A LABEL,
  never guessed into a status.
- Issues are not shared outside the repo's collaborators for now (the repos are private).
