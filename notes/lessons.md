# Lessons

- Lessons that hold in every repo are in `.claude/rules/shared-lessons.md` (synced); this file keeps the ones about
  the master copy itself. The cloud and plugin facts moved there on 2026-10-26.

- `SYNC_TOKEN_OWN` (fine-grained token "workflows sync own", furythestunner, claude-mods only) expires 2027-10-25:
  renew it and update the secret before then (verified by the user, 2026-10-26) (check by 2027-10-18)

## Hook candidates

None open. Time estimates (2026-10-26) became `.claude/hooks/estimate-check.mjs`, replaced the same day by
`.claude/hooks/round-timer.mjs`, which measures each round into `notes/rounds.md` (the check fired on every time).
