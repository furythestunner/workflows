---
name: grill-me
description: Interview the user relentlessly about a plan, feature or decision until every open branch is settled, in rounds, each question with a recommended answer. Use when the user says /grill-me, "grill me", "ask me everything", "kérdezz ki", or before a change big enough that a wrong guess would cost a rework.
---

# Grill me

Adapted from mattpocock/skills (`grilling`, MIT, see `../THIRD-PARTY.md`).

Interview the user until you both understand the plan the same way. Think of it as a **design tree**: every
decision opens the decisions that hang off it.

## Rounds

- The **frontier** is every decision whose prerequisites are already settled: the questions you can ask now
  without guessing at an answer you have not heard yet. Ask the whole frontier in one round, however many
  questions that is. There is no cap: a round can have two questions or ten. A question that depends on another
  question in the same round waits for a later round.
- Number the questions across the whole session (Q1, Q2 ... Q14), so the user can answer "Q3 yes, Q5 b".
- Each question: a short title, the question in plain words (what the user would see or do, not code), the options
  when there are some, and your recommended answer. Word it so that "yes" accepts your recommendation.
- Answers reshape the tree: recompute the frontier and ask the next round.
- When a round has at most 4 questions and each is a clear choice, the app's question box may be used (clickable
  answers); otherwise write the round as text:

```
**Q1. <title>**: <question, with options a / b / c if any>
➡️ Recommended: <answer and one-line reason>

**Q2. <title>**: ...
```

## Facts are yours, decisions are the user's

Never ask the user for something you can look up (files, code, the ground truth, the trackers): look it up, or
send a `scout` agent if the repo has one. Don't wait for it: only the questions that depend on that fact wait; ask
the rest of the round now. Every decision goes to the user, and you wait for the answer.

## Done

The grilling is done when the frontier is empty: every branch visited, nothing silently assumed. Then:

1. Write back the agreed plan in a short numbered list and ask the user to confirm it. Act only after the yes.
2. Record the outcome where it belongs, in the same reply (rulings to `questions.md` §2, new work to a GitHub issue in `status::backlog`,
   a rule for Claude to `CLAUDE.md`). A choice that only shapes the task at hand needs no tracker.

The user can stop at any time ("enough", "wrap up"): then summarise what is settled, list what is still open, and
continue from there.
