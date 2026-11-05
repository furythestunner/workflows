# Handoff

Updated: 2026-11-05 (no change to Next, Waiting or Unfinished; the 2026-11-04 Windows test fix and the
brief without a skills list are on main)

## Next (Claude's own work, nothing for you)

1. Upload checks: intranet, website and KolLab.extension are on (2026-11-02). claude-mods waits for the PC test run
   below: in the cloud 20 tests fail in cache-clock and skill-picker, all built around Windows paths (C:/...);
   if they pass on the PC, the cloud is the cause and the check needs a cloud skip.

## Waiting for Balázs (your steps)

- 🟡 Run the claude-mods tests on your PC (added 2026-11-02, about 2 min): Start menu, type `Git Bash`, open it,
  type `cd /c/GitHub/claude-mods` and Enter, then `claude plugin test mods/cache-clock` and Enter, then
  `claude plugin test mods/skill-picker` and Enter. Paste the last 2 lines of each into the chat.
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
