# Handoff

Updated: 2026-11-02 (lesson collector fails every day: Actions may not open pull requests here)

## Next

1. Check the brief in a new session on each work branch (intra-test, extension-test, website-test): all three got
   the synced workflow on 2026-10-23 (intranet#68, KolLab.extension#30, website#10 merged).
2. The drift check reads `main` of each repo, so it lists them as behind until each work branch is merged to `main`.

## Waiting for Balázs

- 🟡 Let the lesson collector open its pull request (added 2026-11-02, about 1 min): on
  github.com/furythestunner/workflows, Settings tab, left menu Actions, General, scroll to "Workflow permissions",
  tick "Allow GitHub Actions to create and approve pull requests", Save. Then Actions tab, collect-lessons, "Run
  workflow". Every daily run since 2026-10-29 failed on this; the `lessons-collect` branch holds the 2 lessons.
- 🟡 Check the new brief, #45 (added 2026-11-02, about 2 min): start a new session on `dev-test` with a question as
  your first message. The answer comes first, then a horizontal line, then the open items as one 🟡 line each. If
  not, say so in the chat.
- 🟡 Try one short `/crew` round, issue #39 (added 2026-10-28, about 10 min): in a project repo with a Ready issue,
  after the sync pull request is merged, type `/crew`, approve the brief, and at the end check that the report has a
  test list with "Claude: ... saw" and "You: ... expect" lines. Then close #39 on GitHub.
- 🟡 Delete the old merged branches in the 3 Kol-Lab repos (added 2026-10-27, about 1 min each): on the repo's page,
  Code tab, "branches" link, bin icon on each old branch. Keep `main` and the work branch (intranet `intra-test`,
  KolLab.extension `extension-test`, website `website-test`).
- 🟡 Say in the chat which projects are before v1.0 (added 2026-10-26, about 1 min): their pull requests then all
  merge by themselves.
- 🟡 Optional: say in the chat which command checks each project (added 2026-10-27, about 2 min): the one its CI
  runs; Claude adds it, pushes there and waits for it to pass.
- 🟡 Say whether Claude may delete the switched-off "Workflow drift check" scheduled task (added 2026-10-23, about
  1 min): Claude made it on 2026-10-23 without repos, so it could not read the private repos; the one from the
  claude.ai page replaced it.

All of these are also in issue https://github.com/furythestunner/workflows/issues/35 (tick them off there).

## Unfinished

- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
