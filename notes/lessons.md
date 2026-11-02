# Lessons

- Lessons that hold in every repo are in `.claude/rules/shared-lessons.md` (synced); this file keeps the ones about
  the master copy itself. The cloud and plugin facts moved there on 2026-10-26.

- `SYNC_TOKEN_OWN` (fine-grained token "workflows sync own", furythestunner, claude-mods only) expires 2027-10-25:
  renew it and update the secret before then (verified by the user, 2026-10-26) (check by 2027-10-18)
- `SYNC_TOKEN` (fine-grained token for the sync to the Kol-Lab-Design-Kft repos) expires 2027-10-24: renew it and
  update the secret before then; the check-by date is the week-before reminder (verified by the user, 2026-11-02)
  (check by 2027-10-17)

## Hook candidates

- 2026-11-01, first correction: the short brief (first message is a task: "3 lines", `session-start.sh` line 13,
  `cloud/setup-script.sh`) left out Next and Waiting for Balázs, against workflow.md (every brief repeats the open
  steps). Balázs could not do his #41 check. At a second time: a check that the brief names the Waiting items.

Earlier: time estimates (2026-10-26) became `.claude/hooks/estimate-check.mjs`, replaced the same day by
`.claude/hooks/round-timer.mjs`, which measures each round into `notes/rounds.md` (the check fired on every time).
