# Handoff

Updated: 2026-11-02 (all 4 projects stay released; notes-only pull requests skip the review; Next and Waiting
renamed so Next reads as Claude's work; handoff goes in the same commit as the work)

## Next (Claude's own work, nothing for you)

1. Upload checks: intranet, website and KolLab.extension are on (2026-11-02). claude-mods is left: 20 of its tests
   fail (2 mods) and one mod takes 50 s, so Balázs decides first.

## Waiting for Balázs (your steps)

- 🟡 Check the brief in each project (added 2026-11-02, about 2 min each): on claude.ai/code start a new session,
  pick the repo (intranet, then KolLab.extension, then website), set the branch to its work branch (`intra-test`,
  `extension-test`, `website-test`) and send a short question. The reply should open with the answer, then a line,
  then the open items as one 🟡 line each. If not, say which repo in the chat.
- 🟡 Try one short `/crew` round, issue #39 (added 2026-10-28, about 10 min): in a project repo with a Ready issue,
  after the sync pull request is merged, type `/crew`, approve the brief, and at the end check that the report has a
  test list with "Claude: ... saw" and "You: ... expect" lines. Then close #39 on GitHub.

All of these are also in issue https://github.com/furythestunner/workflows/issues/35 (tick them off there).

## Unfinished

- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
