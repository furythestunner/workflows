# Shared facts (every repo, read when needed)

Narrow facts that hold in every repo but matter on one topic only. Claude Code does not load this file by itself:
`.claude/rules/shared-lessons.md` names the topics, and Claude reads this file before work on one of them. It
comes from the workflow master copy with the sync: do not edit it in a project repo. Facts end in
`(check by YYYY-MM-DD)`; the brief lists due ones first.

## Claude Code and sessions

- Anthropic's size advice is under 200 lines per CLAUDE.md; longer files cost context and are followed less well
  (Claude Code docs, memory page, "Write effective instructions"). The tighter limits in `scripts/check.sh` (60 for
  CLAUDE.md, 80 for `.claude/rules/workflow.md`) are this setup's own, because those files and this one all load in
  every session. (check by 2027-01-26)
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
- GitHub does not enforce rulesets on a private repo of a free account (personal or organization): the ruleset
  page shows "won't be enforced ... until you move to GitHub Team". There, "Automatically delete head branches"
  would delete the work branch at its next merge to `main`, so leave it off; "Allow auto-merge" is greyed out, so
  Claude merges by hand once the checks pass. Both GitHub accounts are on the free plan: furythestunner (claude-mods
  private, workflows public) and the Kol-Lab-Design-Kft organization (all private) (verified by the user, 2026-10-27)
  (check by 2027-10-27)
- The Microsoft 365 connector's SharePoint upload takes at most 1 MB per file and needs the whole file inline in
  the call, so a Word or PDF guide with screenshots cannot be uploaded by Claude: create the folder with the
  connector, put the files in Downloads, and the user drags them in (27 Oct 2026, intranet user guides).
  (check by 2027-01-27)
- Reading a web page now runs as a small "web fetch" subagent on Haiku (seen 2026-11-05 in a workflows cloud
  session and the intranet desktop session): the session gets the agent's summary, not the page. That is Claude
  Code's own change, not `/crew` and not this workflow. (check by 2027-02-05)
- Fast mode (`/fast`) is paid from usage credits only, never from the subscription's included usage, and in a
  cloud session it lasts that session only (Claude Code docs, fast mode page) (check by 2027-02-02)

## The user's Windows PCs

- Node on Windows cannot open a Git Bash path like `/tmp/...`: a test that hands a temp folder to node converts it
  first (`command -v cygpath >/dev/null && tmp=$(cygpath -m "$tmp")`), or it fails only on the PC, never in CI.
- In the desktop app on the user's Windows PC the Bash tool drops backslashes inside heredocs (`\\` and `\K` arrive
  broken): write text with Windows paths or regexes through the Edit / Write tools, not a heredoc script.
- The office PCs get PowerShell execution policy RemoteSigned from group policy (seen 2026-10-26; not there on
  2026-10-13): an unsigned .ps1 run from the O: network drive fails even with `-ExecutionPolicy Bypass`. Start a
  local copy of the script instead. (check by 2027-01-26)
- Python is not installed on the user's home PC (DESKTOP-FURY): `python3` there is the Microsoft Store
  placeholder, so a check that needs Python skips itself where `python3 -c ''` fails (seen 2026-11-02).
  (check by 2027-02-02)
