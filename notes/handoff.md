# Handoff

Updated: 2026-10-27 (#5, #12, #14, #16 closed; open steps in #35)

## Next

1. Check the brief in a new session on each work branch (intra-test, extension-test, website-test): all three got
   the synced workflow on 2026-10-23 (intranet#68, KolLab.extension#30, website#10 merged).
2. The drift check reads `main` of each repo, so it lists them as behind until each work branch is merged to `main`.

## Waiting for Balázs

All of these are also in issue https://github.com/furythestunner/workflows/issues/35 (tick them off there).

- Delete the old merged branches in the 3 Kol-Lab repos, if not done yet (about 1 min each): on the repo's page,
  Code tab, "branches" link, bin icon on each old branch. Keep `main` and the work branch (intranet `intra-test`,
  KolLab.extension `extension-test`, website `website-test`). (GitHub settings are done in all 5 repos, 2026-10-27:
  rulesets only in workflows, the only public one; the others are on the free plan, where rulesets do nothing.)
- Say in the chat which projects are before v1.0 (their pull requests then all merge by themselves).
- Optional: say in the chat which command checks each project (the one CI runs); Claude adds it, and pushes there
  then wait for it to pass.
- Tell me when the SYNC_TOKEN token expires, so I can set a reminder a week before: github.com, your profile
  picture (top right), Settings, Developer settings (bottom of the left list), Personal access tokens,
  Fine-grained tokens; the date is next to the token used for the sync.
- Drift check: say whether Claude may delete the disabled personal-account task (the new one works).

## Running

- Scheduled task "Workflow drift check" on the personal account: DISABLED on 2026-10-23 (its test run could not
  reach the private project repos).
- Scheduled task "Workflow drift check" (trig_016Rncvz1ZjQntitYgwVUXYM): created 2026-10-23, Mondays 07:43
  Budapest, push to phone. Test run 2026-10-23 OK: all four repos read, all three 4 commits behind, comment on #16.
- Drift issue #16 closed 2026-10-27 (Balázs); the weekly drift check opens a new one when a repo falls behind.

## Unfinished

- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
