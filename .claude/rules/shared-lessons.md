# Shared lessons (every repo)

Lessons that hold in every repo: tools, PCs, Claude Code, how Claude works with the user. Claude Code loads this
file by itself. It comes from the workflow master copy with the sync: do not edit it in a project repo. A new shared
lesson goes under "## Shared (goes to every repo)" in the project's `notes/lessons.md`; the master copy collects it
from there (README, "Shared lessons"). Project-only lessons stay in `notes/lessons.md`. Only everyday rules belong
here; a narrow fact (one tool, one PC, one limit) goes to `.claude/lessons/shared-facts.md`. Stale-able facts end
in `(check by YYYY-MM-DD)`; the brief lists due ones from both files first.

## Claude Code and sessions

- UNKNOWN in the ground truth is never "none": list those PRs or issues with the GitHub tools instead. (Cloud
  sessions block GraphQL, so `gh pr list` fails there; the script reads GitHub through `gh api` REST.)
- A local Claude desktop chat stays on the PC it ran on; a cloud session cannot see it. Context travels only
  through the repo (`notes/handoff.md`, trackers).
- A Claude subscription (claude.ai, Claude Code) does not cover the Claude API: a tool that calls the API needs a
  paid API key, billed per use. Say this before planning any feature that calls Claude from a script. (check by 2027-01-22)
- Narrow facts are in `.claude/lessons/shared-facts.md`, which does not load by itself. Read it before work on:
  what a cloud session can reach (repos, plugins, uploaded skills, claude.ai Projects), scheduled tasks,
  GitHub rulesets and auto-merge on the free plan, SharePoint uploads, web pages read by a subagent, fast
  mode, file size advice, and the user's Windows PCs (Git Bash paths, heredocs, PowerShell policy, Python).

## Working with the user

- Steps the user has to do go in the chat, written out click by click, never "see README" or another file: opening
  the file is a hassle and the steps get missed (Balázs, 2026-10-27, workflows; a hook candidate, first correction).
  Replaced 2026-11-02: the brief repeats open ones as one line each, full steps only when new or asked for; a long
  repeated list buried the answer.
- Every step the user has to do starts with 🟡, in any reply, so they can scan for their part (Balázs, 2026-11-02).
- Multiple-choice questions go through the AskUserQuestion tool (the user taps an option, and "Other" lets them
  type), never as a lettered list in the chat (Balázs, 2026-11-02, workflows).
- "Improve X" is not "replace X": asked to make a colour legend clearer, Claude moved it to a new tab and removed it
  from where it was; the user wanted it kept (KolLab.extension, 2026-10-26; a hook candidate, first correction).
  Keep what exists unless removal was asked; when an option removes something, say so in the question.
- A message with several topics (or several quoted lines of an earlier reply) gets one block per topic, in the
  user's order, with a horizontal line (`---`) between them, like the line after the brief (Balázs, 2026-11-02,
  workflows).
- A short answer like "3 ok" to a numbered list means "do item 3", even when Claude advised against it; when the
  answer and Claude's advice differ, ask through the picker before recording a ruling (Balázs, 2026-11-02,
  workflows; a hook candidate, first correction).
- One question, one decision: an extra feature folded into a recommended option gets picked without being seen.
  Claude put "Excel also saves a PDF" inside the recommended header option; Balázs picked it and later said he
  never asked for a PDF (KolLab.extension, 2026-10-30, first time; a hook candidate). Ask each extra as its own
  question.
