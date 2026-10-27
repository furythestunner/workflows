---
name: diagnosing-bugs
description: Disciplined loop for hard bugs, wrong numbers and slow pages - build a check that fails on this bug first, then hypothesise, fix, and prove it. Use when the user reports something broken, wrong, failing or slow, says "debug this" or "diagnose", or a first quick fix did not work.
metadata:
  short: "Something broken, wrong or slow: proves the bug, then fixes."
---

# Diagnosing bugs

Adapted from mattpocock/skills (`diagnosing-bugs`, MIT, see `../THIRD-PARTY.md`).

Skip a phase only when you can say why. Redact every secret in what you show (`<REDACTED>`).

## 1. Build a check that goes red on this bug

This is the skill. With a **tight** check (one command, seconds, same verdict every run) that fails on *this* bug,
the cause will be found. Without one, reading code is guessing.

Ways to build one, roughly in this order: a failing automated test; a request against the local dev server; a
browser script that opens the page and reads what it shows (rows, numbers, not just the title); replaying real
input (a file, an import, a request) through the same path; comparing the old version with the new one on the
same input; for "sometimes wrong", running it many times or with many inputs.

If only the user can reproduce it (the live site, their browser, their account): give them numbered steps and
ask exactly what they see at each one. Their report is the check.

**Done when** you can name one command (or one set of user steps) that you have already run once, that shows the
user's exact symptom, and that would pass once fixed. If none can be built, stop, say what you tried, and ask for
access, a screenshot or recording, or the input file.

## 2. Reproduce and shrink

Run the check and watch it fail with the symptom the user described, not a nearby one (wrong bug, wrong fix).
Then cut inputs, steps and data one at a time until every part that is left is needed for the failure.

## 3. Hypothesise

Write 3 to 5 ranked hypotheses before testing any. Each makes a prediction: "if X is the cause, changing Y makes
it go away." Show the list to the user in plain words: they often know at once ("we changed that yesterday",
"that person has two contracts"). Don't wait if they are away.

## 4. Probe

Each probe tests one prediction; change one thing at a time. Tag every temporary log with one prefix (for example
`[DEBUG-a4f2]`) so cleanup is one search. For slowness, measure first (a timing before and after), then cut.

## 5. Fix and lock it in

Turn the shrunk case into an automated test before the fix, if the project has tests that reach this code in the
same way the bug did. Watch it fail, fix, watch it pass, then run the original check from phase 1 again. If no test
can reach it the right way, say so: that is a finding.

## 6. Clean up before saying it is done

- The phase 1 check passes; the new test passes (or why there is none is written down).
- No `[DEBUG-` lines left; throwaway scripts deleted.
- The commit or pull request says which hypothesis was right, and the user hears it in plain words: what was
  wrong, what they will see now, and whether any data already affected needs fixing.
