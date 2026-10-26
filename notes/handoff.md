# Handoff

Updated: 2026-10-26

## Next

1. Check the brief in a new session on each work branch (intra-test, extension-test, website-test): all three got
   the synced workflow on 2026-10-23 (intranet#68, KolLab.extension#30, website#10 merged).
2. The drift check reads `main` of each repo, so it lists them as behind until each work branch is merged to `main`.

## Waiting for Balázs

- claude-mods joins the sync: create the `SYNC_TOKEN_OWN` token (README.md, "The token"), then merge the pull
  request that adds it to `sync/repos.txt`. The sync then opens claude-mods' first "Workflow update" pull request.

- Branches: in each repo, the one-time settings in README.md, "Delete merged branches by themselves" (about 2 min
  each), then delete the old merged branches once on the Branches page.
- Merge #22 (dev-test → main): from then on the sync merges its own "Workflow update" pull requests, including the
  ones open now in intranet, KolLab.extension and website.
- Say "close #5 and #16" in a chat once the brief looks right; Claude may close issues you name now.
- SYNC_TOKEN expiry: put its date in `notes/lessons.md` with a `(check by YYYY-MM-DD)` tag a week before it.
- Drift check: say whether Claude may delete the disabled personal-account task (the new one works).
- #12 and #14 can be closed (dev-test exists; skills stay in the repos): say "close #12 and #14".

## Running

- Scheduled task "Workflow drift check" on the personal account: DISABLED on 2026-10-23 (its test run could not
  reach the private project repos).
- Scheduled task "Workflow drift check" (trig_016Rncvz1ZjQntitYgwVUXYM): created 2026-10-23, Mondays 07:43
  Budapest, push to phone. Test run 2026-10-23 OK: all four repos read, all three 4 commits behind, comment on #16.
- Drift issue https://github.com/furythestunner/workflows/issues/16 (open; closes when #5 is rolled out).

## Unfinished

- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
