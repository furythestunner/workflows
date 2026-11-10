# Skills cheat sheet

The one list of what is here and when to use it, for you. Claude Code shows Claude the skills by itself, so no hook
prints this file. Update it in the same commit when a skill is added, renamed or changes what it is for.

## Skills (type the command)

- `/session-start`: a brief on where things stand (stale facts, branches, open PRs and CI, open issues by status,
  the handoff) and a proposed task. Runs
  by itself at the start; type it after `/clear` or when you ask "where are we?".
- `/handoff`: the end-of-session tidy-up; writes `notes/handoff.md` and the trackers, then commits and pushes. Use it
  before closing, switching machines or `/clear`.
- `/grill-me`: Claude interviews you in rounds until every open question in a plan is settled, each with a
  recommended answer ("yes" accepts it). Use it before a big change where a wrong guess means rework.
- `/questionnaire`: turns questions only someone else can answer (`questions.md` §1) into a short document for that
  person. Use it when you are blocked on a client, owner or colleague.
- `/wait-what`: re-explains Claude's last message in plain words, with the missing context. Use it whenever an
  answer did not land.
- `/pr-body`: the shape of a pull request description: what changes, evidence, merge danger. Used when a pull request
  is opened; type it to ask how risky a merge is.
- `/diagnosing-bugs`: a bug loop that first builds a check that fails on the bug, then hypotheses, fix and proof. Use
  it for anything broken, wrong or slow, or when a quick fix did not work.
- `/issue-run`: what the scheduled runs follow (`check` by day, `build` after midnight). They take only the issues
  you set to Ready; questions come as comments on the issue. Type it to run a check by hand.
- `/code-review` (built in): reviews the diff for bugs. Runs before every pull request opens (CLAUDE.md); type it
  to review any branch or pull request by hand.
- `/never-again`: turns a mistake that happened twice, or a slow or error-filled session, into a hook, a check or a
  rule so it does not happen again. Starts when you correct Claude a second time, and at `/handoff`.
- `/plain`: explains a change or pull request in plain words, ready to paste, or walks you through how a page or
  feature works ("how does X work?"). Every pull request description gets an "In plain words" section from it.
- `/verify`: checks each review comment against the code before acting on it, then fixes it or answers with a
  reason. Runs by itself when a review arrives on a pull request.
- `/distill`: shortens a long text and checks item by item that nothing important was lost. Use it when a rules
  file or note grows too long (the check script warns).
- `/crew`: runs a backlog item as a crew; this session plans, talks to you and reviews, Haiku scouts read, a Sonnet
  implementer writes and a Sonnet reviewer checks. You get a test list of only what Claude could not check. Use it
  for a bigger feature round you want done with workers.

## Hooks (run by themselves)

- `session-start.sh`: at every start, moves a cloud session to the work branch, runs the ground truth and loads the
  handoff.
- `run.mjs`: every hook starts through it. It holds the off switch (you create the file `.claude/workflow-off` on
  GitHub when a hook update breaks the sessions: then no hook runs) and counts how often each hook fires and each
  skill is used, in `notes/usage.md`.
- `cloud/setup-script.sh`: pasted once into the cloud environment's Setup script, so a session with several repos
  also opens with the brief (one per repo).
- `handoff-check.sh`: after every reply, sends Claude back once to update the handoff: after pushed commits, after
  4 of your messages (only if something changed), and when the conversation passes 300k tokens (then it tells you
  to start a new session). So you never need to type `/handoff` before closing a session.
- `decision-check.mjs`: after every reply, asks Claude to record a decision you made that no tracker holds yet.
- `issue-guard.mjs`: before every GitHub action, stops Claude from moving an issue to Ready or closing it;
  only you do that, on GitHub. Back to Backlog is allowed. `labels.sh` creates the issue labels.
- `branch-guard.mjs`: before every git push or new branch, blocks any branch name other than the work branch,
  `<work branch>-<topic>` or `workflow-sync`.
- `push-check.mjs`: before every git push, runs the repo's checks (`CHECK` in `ground-truth.conf`); a failure stops it.
- `secret-guard.mjs`: stops a commit or push that holds a password, token or key file.
- `review-guard.mjs`: stops a pull request from opening before `/code-review` has run (not when only `notes/`
  changed).
- `synced-guard.mjs`: in a project repo, stops edits to files that come from the master copy.
- `fact-check.mjs`: when a reply says the repo has or lacks something unchecked, sends Claude back to look.
- `dash-check.mjs`: when CLAUDE.md says no em dashes and the last reply had one, reminds Claude.
