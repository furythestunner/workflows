# Shared lessons (every repo)

Everyday lessons for every repo: tools, PCs, Claude Code, working with the user. From the master copy: do not edit
it in a project repo. Where a new lesson goes: `.claude/rules/workflow.md`, "Project or shared". A narrow fact (one
tool, one PC, one limit) goes to `.claude/lessons/shared-facts.md`.

## Claude Code and sessions

- UNKNOWN in the ground truth is never "none": list those PRs or issues with the GitHub tools instead. (Cloud
  sessions block GraphQL, so `gh pr list` fails there; the script reads GitHub through `gh api` REST.)
- A local Claude desktop chat stays on the PC it ran on; a cloud session cannot see it. Context travels only
  through the repo (`notes/handoff.md`, trackers).
- A Claude subscription (claude.ai, Claude Code) does not cover the Claude API: a tool that calls the API needs a
  paid API key, billed per use. Say this before planning any feature that calls Claude from a script. (check by 2027-01-22)
- Narrow facts are in `.claude/lessons/shared-facts.md`, which does not load by itself. Read it before work on:
  what a cloud session can reach (repos, plugins, uploaded skills, claude.ai Projects, YouTube), scheduled tasks,
  GitHub rulesets and auto-merge on the free plan, SharePoint uploads, web pages read by a subagent, fast
  mode, file size advice, and the user's Windows PCs (Git Bash paths, heredocs, PowerShell policy, Python,
  screenshots of a page, the desktop app's browser pane).

## Working with the user

- Simple language in every reply and every text for the user, after ASD-STE100 (Simplified Technical English,
  made for readers whose first language is not English). A trial in the master copy from 2026-11-10, kept for
  every repo by Balázs on 2026-11-19:
  - Short sentences: at most about 20 words, one idea each. A step is one sentence with one action.
  - Active voice, present tense: "The hook stops the push", not "The push will be stopped by the hook".
  - One name per thing: once it is "the sync pull request", it stays that in the whole reply.
  - Common words: "use", not "leverage"; "important", not "load-bearing" or "critical path".
  - Say what is happening, not what you will do: "Checking the tests", not "Now I'll run the tests to check".
  - Shorter must not change the claim: keep every condition, number and "may". "It may have failed" stays "may
    have failed", never "it failed".
- Steps the user has to do: the rule is in `.claude/rules/workflow.md`. Why: in another file the steps get missed,
  and a long repeated list buried the answer (Balázs, 2026-10-27 and 2026-11-02; a hook candidate, first correction).
- The handoff's Waiting list holds only steps the user clicks or checks himself. "Tell X" (a colleague, the owner)
  goes once into the chat message after a merge, never into Waiting: 20 such small items piled up there and the
  user did not know why (Balázs, 2026-11-04, intranet; first correction, a hook candidate).
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
