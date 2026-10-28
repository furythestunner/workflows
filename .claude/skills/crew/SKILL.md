---
name: crew
description: Run a feature round as a crew. The main session is the orchestrator (plans, talks to the user, reviews, commits) and hands the reading to Haiku scouts and the writing to a Sonnet implementer. Use it when the user says /crew, "crew round", or asks to do a backlog item with workers.
metadata:
  short: "Bigger feature round, done by Haiku and Sonnet helpers."
---

# Crew round

You are the orchestrator: the project manager between the user and the workers. You talk to the user, write the brief,
send the workers, check and review what they did, commit, and report. The workers do the reading and the writing.
Why: the expensive model spends its tokens on judgment, the cheaper models on volume.

## Roles

| Role | Model | Can | Used for |
|---|---|---|---|
| Orchestrator (you) | the session's | everything; the only one who commits and talks to the user | brief, review, checks, commit, report |
| `scout` | Haiku | read and search only | "where is X", "which files use Y", "what does Z look like now" |
| `implementer` | Sonnet | edit files, run commands | the change itself, its checks, the check in the app |
| `reviewer` | Sonnet | read only | the diff against the brief, item by item, before your own review |

- Use `scout`, `implementer` and `reviewer` only. Never the built-in Explore or general-purpose agents: they run on
  the session's own model, so they save nothing.
- The model of each role is set in `.claude/agents/`. the user decides it; never change it or pick another model on
  your own.
- Workers start from zero: they get CLAUDE.md and your message, not this conversation. Everything they need goes into
  the message.

## Steps

1. **Intake.** Find the issue (or take the user's words) and re-confirm it is still open. Start only a
   `Status: Ready` issue (the user approved it) and set it to `Status: In progress`. Check the branch: the work branch (`WORK_BRANCH` in `.claude/ground-truth.conf`), up to date
   with `main` (CLAUDE.md, Git workflow).
2. **Scout** (skip when you already know where everything is). One question per scout; several scouts may run in
   parallel. Before you build the plan on a finding, open the cited line yourself: a scout's finding is a lead, not a
   fact.
3. **Brief and approval.** Write the brief (template below) into the round record `notes/crew/<YYYY-MM-DD>-<slug>.md`.
   Show the user the plan in their terms: what changes for the people who use it, why, size, and anything CLAUDE.md
   says to ask before (a schema change, a shared library, an outside service). **Wait for their OK.** A finding or a plan is not a go-ahead.
4. **Implement.** Send the brief to one `implementer`, word for word. One implementer at a time: they share the
   working copy. Split a large round into briefs that run one after another, each reviewed before the next starts.
5. **Fence, then check.** First run `bash .claude/skills/crew/fence.sh <round record>`: any file outside the
   brief's "Files:" goes back to the implementer before any review (it counts as a send-back). A worker's "pass" is
   not proof. Rerun the fast checks from CLAUDE.md ("Before saying a change is
   done") yourself. A check that runs the app and looks at the result stays with the implementer; read what it says
   it saw. Say plainly what no check here can cover (e.g. a test only the user can run).
6. **Review.** Send the brief, word for word, to one `reviewer`. Open each of its findings at the cited line
   before you act on it. Then review the diff (`git diff`) yourself against the brief and the checklist below. Then
   one of:
   - **Accept.**
   - **Fix it yourself** when the fix is a few lines; say so in the report.
   - **Send back** to a new `implementer` with the brief plus a numbered list of exactly what to fix. At most 2
     send-backs; after that, stop and ask the user.
7. **Commit, push, pull request.** Stage the changed paths by name, read `git diff --cached --name-only`, commit to
   the work branch, push, and open or update the one pull request from it to `main` (a migration or other manual step
   is named at the top; the body says "Closes #<n>"), then set the issue to `Status: Review`. Never merge.
8. **Report** to the user per CLAUDE.md: what changed for the people who use it, how it was checked, and the smoke
   list: every step of "Done when", each marked `[x] Claude: <step>, saw <what>` (what a worker or you ran and saw)
   or `[ ] You: <step>, expect <what>` (clicks written out). Put it in the chat, the round record and the pull
   request, so the user tests only what no check here could. Fill the round record's "Crew log" and add its line
   to `notes/crew/log.md` (create it from the table under "Round record" if it is missing).

## Review checklist

- Only what the brief asked; nothing from "Out of scope"; no stray files (`git status`).
- CLAUDE.md's hard rules, each one the change could touch.
- CLAUDE.md's conventions (and its database or versioning rules, where it has them).
- Nothing from CLAUDE.md's "Ask before" list without the user's OK.
- README updated when something people use or the workflow changed.

## Brief template

```
# <title>
Ask: <the user's words, as they said them, plus the context needed to read them>
Context: <what the scouts found, as path:line; what exists now>
Spec: <what to build: files, behaviour, labels the user sees>
Files: <every path the implementer may change or add; a folder ends in /; * works>
Out of scope: <what stays untouched, named>
Done when:
- <checks to run>
- <what the user must see (rows, numbers, labels, a dialog) and how to get there>
Report: use your report format.
```

## Round record

`notes/crew/<YYYY-MM-DD>-<slug>.md` holds the brief, then a "Status" line (planned / approved / in review / in PR
#n), then the "Crew log": scouts sent, implementer runs, send-backs and why (fence, reviewer, you), scope slips,
scout findings that were wrong. It is committed with the round, so a session on another machine can pick the round
up. Delete it once its pull request is merged; its line in `notes/crew/log.md` stays. The log is the pilot's evidence for keeping, tuning or
dropping the crew setup, next to what the user reads in `/usage` (the share used by subagents).

`notes/crew/log.md` starts as:

```
# Crew rounds log

| Date | Round | PR | Scouts | Implementer runs | Send-backs | Scope slips | Wrong scout findings | /usage subagent share |
|---|---|---|---|---|---|---|---|---|
```
