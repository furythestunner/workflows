# Handoff

Updated: 2026-11-02 (all 4 projects stay released; notes-only pull requests skip the review; Next and Waiting
renamed so Next reads as Claude's work; handoff goes in the same commit as the work)

## Next (Claude's own work, nothing for you)

1. Upload checks in the projects (Balázs said yes to all 4, 2026-11-02). Done: intranet (`npm test`, 27 tests) and
   website (syntax check), pushed to their work branches. Left: KolLab.extension, after Balázs says how Python
   starts on his PC; claude-mods, where 20 tests fail (2 mods) and one mod takes 50 s: ask him before adding it.

## Waiting for Balázs (your steps)

- 🟡 Check the brief in each project (added 2026-11-02, about 2 min each): on claude.ai/code start a new session,
  pick the repo (intranet, then KolLab.extension, then website), set the branch to its work branch (`intra-test`,
  `extension-test`, `website-test`) and send a short question. The reply should open with the answer, then a line,
  then the open items as one 🟡 line each. If not, say which repo in the chat.
- 🟡 Say how Python starts on your PC, for the KolLab.extension check (added 2026-11-02, about 1 min): Start menu,
  type `Git Bash`, open it, type `python3 --version` and press Enter, then `python --version` and Enter. Paste
  what both print into the chat.
- 🟡 Try one short `/crew` round, issue #39 (added 2026-10-28, about 10 min): in a project repo with a Ready issue,
  after the sync pull request is merged, type `/crew`, approve the brief, and at the end check that the report has a
  test list with "Claude: ... saw" and "You: ... expect" lines. Then close #39 on GitHub.

All of these are also in issue https://github.com/furythestunner/workflows/issues/35 (tick them off there).

## Unfinished

- `dev-test`: review guard for notes-only pull requests, the Next and Waiting rename, the same-commit handoff rule
  and 2 shared lessons; pull request to `main` opening now.
- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
