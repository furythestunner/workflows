# Handoff

Updated: 2026-11-02 (Balázs: new brief works (#45), old Kol-Lab branches deleted; speed options under discussion)

## Next

1. Check the brief in a new session on each work branch (intra-test, extension-test, website-test): all three got
   the synced workflow on 2026-10-23 (intranet#68, KolLab.extension#30, website#10 merged).
2. The drift check reads `main` of each repo, so it lists them as behind until each work branch is merged to `main`.

## Waiting for Balázs

- 🟡 Try one short `/crew` round, issue #39 (added 2026-10-28, about 10 min): in a project repo with a Ready issue,
  after the sync pull request is merged, type `/crew`, approve the brief, and at the end check that the report has a
  test list with "Claude: ... saw" and "You: ... expect" lines. Then close #39 on GitHub.
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
