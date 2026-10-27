---
name: never-again
description: Turn a mistake that happened twice, or friction in a session, into a hook, a check or a rule so it does not happen again. Use when the user says /never-again, "never again", "this keeps happening", "soha többé", "megint ez", when a correction is already listed under "Hook candidates" in notes/lessons.md, or at the end of a session (/handoff step 5) when something went wrong or was slow.
metadata:
  short: "A mistake happened twice: turns it into a hook or rule."
---

# Never again

Adapted from integralist/agent-skills (`durable-rules`, see `../THIRD-PARTY.md`).

Look back at what went wrong and propose a lasting fix, so the next session does not repeat it. A one-off slip is
not a rule. A rule written only as prose is the weakest fix: prefer a hook or a check whenever one can catch it.

1. **Read what happened.** This session's conversation, the corrections the user made, and "Hook candidates" in
   `notes/lessons.md`. Done when you can name each thing that went wrong or was slow, with one example.
2. **Sort each one:**
   - **A correction the user made twice** (it is under "Hook candidates" already): the top finding. Propose a hook
     that blocks or flags it.
   - **An error a check could have caught:** a wrong path, a broken script, a missed step. Look at the checks the
     repo has (`scripts/check.sh`, CI, CLAUDE.md "Before saying a change is done"); a check that exists but did not
     run is a finding too.
   - **A judgement call Claude got wrong** that a hook cannot see: a rule line.
   - **Slow work:** files that took many searches to find, the same file read again and again, missing access that
     forced a guess.
   - **A skill that misfired,** or a workflow repeated by hand that has no skill.

   If nothing lasting surfaced, say so and stop. Done when each item has a kind.
3. **Pick where each fix goes.** Update a file that already covers the topic before adding a new one.

   | Fix | Where |
   |---|---|
   | Hook, workflow rule, skill change, cheat sheet | The master copy (github.com/furythestunner/workflows). In a project repo: a GitHub issue there, never an edit here (synced files, `.claude/workflow-manifest`) |
   | A check for this project's code | The project's own checks, named in its CLAUDE.md |
   | A rule only this project needs | The project's CLAUDE.md |
   | A lesson, a tool quirk, a fact that can go stale | `notes/lessons.md` (a stale-able fact ends in `(check by YYYY-MM-DD)`); one that holds in any repo under its `## Shared (goes to every repo)` section |
   | A first correction | One line under "Hook candidates" in `notes/lessons.md`: date, what was corrected |

   Done when every item has a place.
4. **Show, then write.** List the proposals, most harmful first, each in one line: what went wrong, the fix, where it
   goes, with your recommendation. Write only what the user approves. A new hook gets a test next to it, like
   `.claude/hooks/issue-guard.test.sh`. When a "Hook candidates" line is fixed by a hook, remove the line. Done when
   the approved fixes are written, or the issue for the master copy is open.

Talk in plain words: name what the user saw go wrong, not code names.
