# Handoff

Updated: 2026-11-02 (new brief works, old branches and the old drift task deleted; speed options and project check
commands under discussion: no project has GitHub test runs, none sets CHECK or MERGE_MODE)

## Next

Nothing of Claude's own: everything open waits for Balázs (Next holds only Claude's work, Waiting only the user's).

## Waiting for Balázs

- 🟡 Check the brief in each project (added 2026-11-02, about 2 min each): on claude.ai/code start a new session,
  pick the repo (intranet, then KolLab.extension, then website), set the branch to its work branch (`intra-test`,
  `extension-test`, `website-test`) and send a short question. The reply should open with the answer, then a line,
  then the open items as one 🟡 line each. If not, say which repo in the chat.

- 🟡 Try one short `/crew` round, issue #39 (added 2026-10-28, about 10 min): in a project repo with a Ready issue,
  after the sync pull request is merged, type `/crew`, approve the brief, and at the end check that the report has a
  test list with "Claude: ... saw" and "You: ... expect" lines. Then close #39 on GitHub.
- 🟡 Say in the chat which projects are before v1.0 (added 2026-10-26, about 1 min): their pull requests then all
  merge by themselves.
- 🟡 Optional: say in the chat which command checks each project (added 2026-10-27, about 2 min): the one its CI
  runs; Claude adds it, pushes there and waits for it to pass.

All of these are also in issue https://github.com/furythestunner/workflows/issues/35 (tick them off there).

## Unfinished

- `dev-test` has a shared lesson (fast mode cost) and a README ruling not on `main` yet: they go with the next
  pull request.
- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
