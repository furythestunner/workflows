# Skills cheat sheet

The one list of what is here and when to use it. `session-start.sh` prints it at every start and the brief shows it;
update it in the same commit when a skill is added, renamed or changes what it is for.

## Skills (type the command)

- `/session-start`: a brief on where things stand (branches, open PRs and CI, the handoff) and a proposed task. Runs
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
- `/crew`: runs a backlog item as a crew; this session plans, talks to you and reviews, Haiku scouts read and a
  Sonnet implementer writes. Use it for a bigger feature round you want done with workers.

## Hooks (run by themselves)

- `session-start.sh`: at every start, moves a cloud session to the work branch, runs the ground truth and loads the
  handoff and this list.
- `handoff-check.sh`: after every reply, sends Claude back once to update the handoff when pushed code is newer.
- `decision-check.mjs`: after every reply, asks Claude to record a decision you made that no tracker holds yet.
