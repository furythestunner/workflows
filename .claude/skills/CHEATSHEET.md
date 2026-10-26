# Skills cheat sheet

The one list of what is here and when to use it. `session-start.sh` prints it at every start and the brief shows it;
update it in the same commit when a skill is added, renamed or changes what it is for.

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
- `/plain`: explains a change or pull request in plain words, ready to paste. Every pull request description gets an
  "In plain words" section from it; type it, or ask "what changed?".
- `/verify`: checks each review comment against the code before acting on it, then fixes it or answers with a
  reason. Runs by itself when a review arrives on a pull request.
- `/distill`: shortens a long text and checks item by item that nothing important was lost. Use it when a rules
  file or note grows too long (the check script warns).
- `/crew`: runs a backlog item as a crew; this session plans, talks to you and reviews, Haiku scouts read and a
  Sonnet implementer writes. Use it for a bigger feature round you want done with workers.

## Hooks (run by themselves)

- `session-start.sh`: at every start, moves a cloud session to the work branch, runs the ground truth and loads the
  handoff and this list.
- `cloud/setup-script.sh`: pasted once into the cloud environment's Setup script, so a session with several repos
  also opens with the brief (one per repo, this list once).
- `handoff-check.sh`: after every reply, sends Claude back once to update the handoff when pushed code is newer.
- `decision-check.mjs`: after every reply, asks Claude to record a decision you made that no tracker holds yet.
- `skill-nudge.mjs`: on every message you send, names the skill that fits (English and Hungarian phrases), so
  Claude uses it without you typing it. A review on a pull request always goes through `/verify`.
- `round-timer.mjs`: after every reply that made a commit, writes how long it took to `notes/rounds.md`; the brief
  shows the latest, so time estimates come from measured rounds, not from feel.
- `lesson-check.mjs`: after a reply that added a lesson, has Claude sort it: only this project, or shared (it then
  reaches every repo through the master copy, `.claude/rules/shared-lessons.md`).
- `issue-guard.mjs`: before every GitHub action, stops Claude from moving an issue to Ready or Done or closing it;
  only you do that, on GitHub. Moving one back to Backlog or Blocked is allowed. `labels.sh` (next to the ground
  truth) creates the issue labels.
- `branch-guard.mjs`: before every git push or new branch, blocks any branch name other than the work branch,
  `<work branch>-<topic>` or `workflow-sync`.
