# Shared lessons (every repo)

Lessons that hold in every repo: tools, PCs, Claude Code, how Claude works with the user. Claude Code loads this
file by itself. It comes from the workflow master copy with the sync: do not edit it in a project repo. A new shared
lesson goes under "## Shared (goes to every repo)" in the project's `notes/lessons.md`; the master copy collects it
from there (README, "Shared lessons"). Project-only lessons stay in `notes/lessons.md`. Stale-able facts end in
`(check by YYYY-MM-DD)`, as in `notes/lessons.md`; the brief lists due ones first.

## Claude Code and sessions

- UNKNOWN in the ground truth is never "none": list those PRs or issues with the GitHub tools instead. (Cloud
  sessions block GraphQL, so `gh pr list` fails there; the script reads GitHub through `gh api` REST.)
- Anthropic's size advice is under 200 lines per CLAUDE.md; longer files cost context and are followed less well
  (Claude Code docs, memory page, "Write effective instructions"). The tighter limits in `scripts/check.sh` (60 for
  CLAUDE.md, 80 for `.claude/rules/workflow.md`) are this setup's own, because those files and this one all load in
  every session. (check by 2027-01-26)
- A local Claude desktop chat stays on the PC it ran on; a cloud session cannot see it. Context travels only
  through the repo (`notes/handoff.md`, trackers).
- A cloud session can only reach repos the Claude GitHub App is installed on: the Kol-Lab-Design-Kft organization,
  not the user's personal repos. (check by 2027-01-22)
- Plugins declared in a repo's `.claude/settings.json` do not load in cloud sessions; skills, agents and hooks in
  the repo do (Claude Code docs, settings page, "Settings in cloud sessions") (check by 2027-01-23)
- In claude.ai Projects threads, a repo's `.claude/settings.json` hooks, permission rules and `env` do not apply,
  so this workflow's hooks do not run there (same docs section) (check by 2027-01-23)
- Skills uploaded to the claude.ai account load in cloud sessions: fpl-copilot and transcript-to-kb were listed in
  a workflows cloud session on 2026-10-23 (check by 2027-01-23)
- A scheduled task Claude creates with create_trigger has no repositories and no connectors: its session cannot
  attach private repos (GitHub 403). Create tasks that need private repos from the claude.ai scheduled tasks page,
  with the repos selected (check by 2027-01-23)
- A Claude subscription (claude.ai, Claude Code) does not cover the Claude API: a tool that calls the API needs a
  paid API key, billed per use. Say this before planning any feature that calls Claude from a script. (check by 2027-01-22)

- GitHub does not enforce rulesets on a private repo of a free account (personal or organization): the ruleset
  page shows "won't be enforced ... until you move to GitHub Team". There, "Automatically delete head branches"
  would delete the work branch at its next merge to `main`, so leave it off; "Allow auto-merge" is greyed out, so
  Claude merges by hand once the checks pass (seen on furythestunner/claude-mods, 2026-10-27). (check by 2027-01-27)

## The user's Windows PCs

- In the desktop app on the user's Windows PC the Bash tool drops backslashes inside heredocs (`\\` and `\K` arrive
  broken): write text with Windows paths or regexes through the Edit / Write tools, not a heredoc script.
- The office PCs get PowerShell execution policy RemoteSigned from group policy (seen 2026-10-26; not there on
  2026-10-13): an unsigned .ps1 run from the O: network drive fails even with `-ExecutionPolicy Bypass`. Start a
  local copy of the script instead. (check by 2027-01-26)

## Working with the user

- Steps the user has to do go in the chat, written out click by click, never "see README" or another file: opening
  the file is a hassle and the steps get missed. Repeat open ones in every brief until done (Balázs, 2026-10-27,
  workflows; a hook candidate, first correction).
- "Improve X" is not "replace X": asked to make a colour legend clearer, Claude moved it to a new tab and removed it
  from where it was; the user wanted it kept (KolLab.extension, 2026-10-26; a hook candidate, first correction).
  Keep what exists unless removal was asked; when an option removes something, say so in the question.
