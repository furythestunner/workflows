# Handoff

Updated: 2026-11-01 (#43 open: the short brief keeps Next and Waiting)

## Next

1. Check the brief in a new session on each work branch (intra-test, extension-test, website-test): all three got
   the synced workflow on 2026-10-23 (intranet#68, KolLab.extension#30, website#10 merged).
2. The drift check reads `main` of each repo, so it lists them as behind until each work branch is merged to `main`.

## Waiting for Balázs

- Issue #41 (the handoff now updates itself): nothing to do on a normal day; just close sessions without typing
  `/handoff`. Within the next week, check once (about 2 min): open a new session on `dev-test` and see that the
  brief's Next and Waiting lines match what you did last time. If something is missing, say so in the chat.
  Also say if 150k tokens is too early or too late for the "start a new session" reminder.

- Issue #39 (/crew additions, merged in #40): try one short `/crew` round (about 10 min). In a project repo with a
  Ready issue, after the sync pull request is merged: type `/crew`, approve the brief, and at the end check that the
  report has a test list with "Claude: ... saw" and "You: ... expect" lines. Then close #39 on GitHub.

- Short brief fix (pull request #43, merges by itself once its checks pass): after it merges, open a new session
  on `dev-test` and start with a task (for example "check issue #38"). The first reply should still list Next
  and Waiting for you, with the steps written out. If not, say so in the chat (about 2 min).

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

## Unfinished

- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
