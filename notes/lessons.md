# Lessons

- Lessons that hold in every repo are in `.claude/rules/shared-lessons.md` (synced); this file keeps the ones about
  the master copy itself. The cloud and plugin facts moved there on 2026-10-26.

- `SYNC_TOKEN_OWN` (fine-grained token "workflows sync own", furythestunner, claude-mods only) expires 2027-10-25:
  renew it and update the secret before then (verified by the user, 2026-10-26) (check by 2027-10-18)

- Measured rounds (Claude's estimates by feel ran 4 to 6 times too high; estimate from these, add each new one): 4 skills
  adapted + 1 hook with tests + check script + docs + code review with 8 fixes + pull request = about 15 min
  (issue #20, 2026-10-26); 1 Stop hook with tests + rule + docs = about 5 min (2026-10-26); 1 guard change with 15 tests + sync change + README guide + code review with 2 fixes = about 15 min
  (2026-10-26). Give Balázs's part
  (reviews, merges) separately

## Hook candidates

None open. Time estimates (2026-10-26) became `.claude/hooks/estimate-check.mjs`.
