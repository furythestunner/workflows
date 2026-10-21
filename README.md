# Claude Code session workflow

Automatic session start, a short handoff and a decision check for Claude Code, in every repo.
Started from github.com/truongfelix/workflow (6d2623c, 2026-10-10).

## Why it is copied into each repo

A cloud session (claude.ai/code, the phone app) reads only the repo's own `.claude/settings.json`. Settings in
`~/.claude` on a PC never reach it, and plugins do not load there. So every repo carries its own copy, and this repo
is the master: change a hook here first, then copy it to each repo.

## What it does

| File | When | What |
|---|---|---|
| `.claude/hooks/session-start.sh` | every session start | Cloud session: switches to `WORK_BRANCH` and pulls. PC: fast-forwards the checked-out branch when nothing is uncommitted or unpushed, otherwise says why not. Runs `ground-truth.sh`, checks whether the handoff is older than the last code commit, prints the handoff. Claude's first reply opens with the brief. |
| `.claude/hooks/handoff-check.sh` | after every reply | If pushed code on `WORK_BRANCH` is newer than the handoff, sends Claude back once to update and push it. |
| `.claude/hooks/decision-check.mjs` | after every reply | If the user answered a multiple-choice question or used decision words and no tracker changed, asks Claude to record the decision. |
| `.claude/skills/session-start/` | `/session-start`, and the hook | The brief, and `ground-truth.sh` (branches against GitHub, uncommitted work, open PRs and CI). |
| `.claude/skills/handoff/` | `/handoff` | The full tidy-up at the end of a session. |
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
3. Create `notes/handoff.md`, `BACKLOG.md`, `questions.md` (§1 open questions, §2 rulings) and `notes/lessons.md`.
4. Add the block below to the repo's `CLAUDE.md` (replace `<work branch>`).
5. Write the commit of this repo into `.claude/workflow-version`, commit, push to the work branch.
6. Check: start a new cloud session; the first reply must open with the brief.

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
- **Decisions go into the trackers in the same reply:** a ruling to `questions.md` §2, new open work to
  `BACKLOG.md`, a rule for Claude to this file, a lesson to `notes/lessons.md`; never only into the chat.
- **Handoff rule:** `/handoff` and the end-of-reply check commit and push the docs (handoff, trackers, `notes/`) to
  `<work branch>` without asking.
- The setup comes from github.com/furythestunner/workflows (`.claude/workflow-version` names the commit). Project
  values go only in `.claude/ground-truth.conf`, never in the scripts.
```
