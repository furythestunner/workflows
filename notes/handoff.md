# Handoff

Updated: 2026-10-26

## Next

1. Check the brief in a new session on each work branch (intra-test, extension-test, website-test): all three got
   the synced workflow on 2026-10-23 (intranet#68, KolLab.extension#30, website#10 merged).
2. The drift check reads `main` of each repo, so it lists them as behind until each work branch is merged to `main`.

## Waiting for Balázs

- Delete 20 merged branches on GitHub by hand (a cloud session gets 403): claude-mods: all except `main` and
  `mods-test`; workflows: the four `claude/...`; intranet: `design-review`, `workflow-sync`, `ccr-1699d267-miqhie`;
  KolLab.extension and website: `workflow-sync`.
- Merge the "Workflow update" pull request in intranet, KolLab.extension and website (#21 merged 2026-10-26; the sync opened them).
- Close #5 (rolled out) and #16 (drift fixed by the sync) on GitHub, once the brief looks right.
- SYNC_TOKEN expiry: put its date in `notes/lessons.md` with a `(check by YYYY-MM-DD)` tag a week before it.
- Drift check: say whether Claude may delete the disabled personal-account task (the new one works).
- Close https://github.com/furythestunner/workflows/issues/14 as not planned (skills stay in the repos).
- Labels on #5, #6 and #12; #12 can be closed (dev-test exists on GitHub).

## Running

- Scheduled task "Workflow drift check" on the personal account: DISABLED on 2026-10-23 (its test run could not
  reach the private project repos).
- Scheduled task "Workflow drift check" (trig_016Rncvz1ZjQntitYgwVUXYM): created 2026-10-23, Mondays 07:43
  Budapest, push to phone. Test run 2026-10-23 OK: all four repos read, all three 4 commits behind, comment on #16.
- Drift issue https://github.com/furythestunner/workflows/issues/16 (open; closes when #5 is rolled out).

## Unfinished

- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
