# Handoff

Updated: 2026-10-23

## Next

1. Roll the workflow out to intranet, KolLab.extension and website (#5) with the new sync: merge the dev-test
   pull request, then run the "sync" action. Each repo gets a "Workflow update" pull request into its work branch.
2. In each of those pull requests, before merging: move the project-specific lines of the old "Sessions and
   trackers" block and of the four edited shared files (implementer, scout, crew, session-start) into that repo's
   CLAUDE.md, then delete the old block. The pull request's "Do before merging" list names them.

## Waiting for Balázs

- Create the fine-grained token and save it as the secret `SYNC_TOKEN` in this repo (README.md, "How the sync
  works", The token). The sync cannot run without it.
- Review and merge the dev-test pull request that adds the sync.

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

Nothing on one disk only.
