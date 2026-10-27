# Handoff

Updated: 2026-10-27 (#24, #25, #27, #28, #30 merged; the sync takes them to the project repos)

## Next

1. Check the brief in a new session on each work branch (intra-test, extension-test, website-test): all three got
   the synced workflow on 2026-10-23 (intranet#68, KolLab.extension#30, website#10 merged).
2. The drift check reads `main` of each repo, so it lists them as behind until each work branch is merged to `main`.

## Waiting for Balázs

- GitHub settings, once per repo (about 3 min each). Done: furythestunner/workflows (2026-10-27). Still to do:
  furythestunner/claude-mods, Kol-Lab-Design-Kft/intranet, Kol-Lab-Design-Kft/KolLab.extension,
  Kol-Lab-Design-Kft/website. On the repo's page:
  1. Settings (top bar), Rules (left), Rulesets, New ruleset, New branch ruleset. Name: `keep main and work branch`.
     Enforcement status: Active. Target branches, Add target, Include by pattern: `main`. Add target again: the work
     branch (workflows `dev-test`, claude-mods `mods-test`, intranet `intra-test`, KolLab.extension
     `extension-test`, website `website-test`).
  2. Same page, under Rules: tick only "Restrict deletions". Create.
  3. Rulesets, New ruleset, New branch ruleset again. Name: `checks before main`. Enforcement status: Active. Add
     target, Include by pattern: `main` only (not the work branch: there it would block every push). Under Rules,
     tick "Require status checks to pass", Add checks, type `check`, pick it. Create. (Nothing shows up for `check`:
     that repo has no check yet; skip this step.)
  4. Settings, General (left), scroll to "Pull Requests": tick "Allow auto-merge" and "Automatically delete head
     branches".
  5. Branches (Code tab, "branches" link): delete the old merged branches with the bin icon; keep `main` and the
     work branch.
- Say in the chat which projects are before v1.0 (their pull requests then all merge by themselves).
- Optional: say in the chat which command checks each project (the one CI runs); Claude adds it, and pushes there
  then wait for it to pass.
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
