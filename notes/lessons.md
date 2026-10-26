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

- `SYNC_TOKEN_OWN` (fine-grained token "workflows sync own", furythestunner, claude-mods only) expires 2027-10-25:
  renew it and update the secret before then (verified by the user, 2026-10-26) (check by 2027-10-18)

- Measured rounds (Claude's estimates by feel ran 4 to 6 times too high; estimate from these, add each new one): 4 skills
  adapted + 1 hook with tests + check script + docs + code review with 8 fixes + pull request = about 15 min
  (issue #20, 2026-10-26); 1 Stop hook with tests + rule + docs = about 5 min (2026-10-26); 1 guard change with 15 tests + sync change + README guide + code review with 2 fixes = about 15 min
  (2026-10-26). Give Balázs's part
  (reviews, merges) separately

## Hook candidates

None open. Time estimates (2026-10-26) became `.claude/hooks/estimate-check.mjs`.
