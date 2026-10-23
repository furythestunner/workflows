# Lessons

- Plugins declared in a repo's `.claude/settings.json` do not load in cloud sessions; skills, agents and hooks in
  the repo do (Claude Code docs, settings page, "Settings in cloud sessions") (check by 2027-01-23)
- In claude.ai Projects threads, a repo's `.claude/settings.json` hooks, permission rules and `env` do not apply,
  so this workflow's hooks do not run there (same docs section) (check by 2027-01-23)
- Skills uploaded to the claude.ai account load in cloud sessions: fpl-copilot and transcript-to-kb were listed in
  a workflows cloud session on 2026-10-23 (check by 2027-01-23)
- A scheduled task Claude creates with create_trigger here has no repositories and no connectors: its session
  cannot attach private repos (GitHub 403). Create tasks that need private repos from the claude.ai scheduled tasks
  page, with the repos selected (check by 2027-01-23)

## Hook candidates

None yet.
