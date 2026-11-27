# Handoff

Updated: 2026-11-27 (/gemini-image-prompt merged in #84; bug #86 found: dev-test can lag main)

## Next (Claude's own work, nothing for you)

1. Shared lessons are collected by hand now: when Balázs says "collect the shared lessons", read the "## Shared"
   section of each project repo's `notes/lessons.md` and write them into the two shared files here.
2. Fact check trial (`fact-check.mjs`, due since 2026-11-17; simple language was decided 2026-11-19): it never
   fired in this repo. Read its count in each project repo's `notes/usage.md` (attach them read-only), then ask
   Balázs: keep or cut.
3. Upload checks: intranet, website and KolLab.extension are on (2026-11-02). claude-mods waits for the PC test run
   below: in the cloud 20 tests fail in cache-clock and skill-picker, all built around Windows paths (C:/...);
   if they pass on the PC, the cloud is the cause and the check needs a cloud skip.

## Waiting for Balázs (your steps)

- 🟡 Delete the `Status: Done` label in 5 repos (added 2026-11-24, about 3 min; the issue guard stops Claude): open
  github.com/furythestunner/workflows/labels, find `Status: Done`, click its `...` menu (or `Delete`), then confirm.
  Do the same in Kol-Lab-Design-Kft/intranet, Kol-Lab-Design-Kft/KolLab.extension, Kol-Lab-Design-Kft/website and
  furythestunner/claude-mods. No open issue uses it.
- 🟡 Check the brief in each project (added 2026-11-02, about 2 min each; the 4 sync pull requests were merged 2026-11-10):
  on claude.ai/code start a new session, pick the repo (intranet, then KolLab.extension, then website), set the
  branch to its work branch (`intra-test`, `extension-test`, `website-test`) and send a short question. The reply
  should open with the brief (about 8 lines, your open steps as one 🟡 line each), then a line, then the answer. If
  not, say which repo in the chat. This also ends the freeze (issue #44).
- 🟡 Run the claude-mods tests on a PC with Claude Code in the terminal, not DESKTOP-FURY (no `claude` command there, 2026-11-22) (added 2026-11-02, about 2 min): Start menu, type `Git Bash`, open it,
  type `cd /c/GitHub/claude-mods` and Enter, then `claude plugin test mods/cache-clock` and Enter, then
  `claude plugin test mods/skill-picker` and Enter. Paste the last 2 lines of each into the chat.
- 🟡 Try one short `/crew` round, issue #39 (added 2026-10-28, about 10 min): in a project repo with a Ready issue,
  after the sync pull request is merged, type `/crew`, approve the brief, and at the end check that the report has a
  test list with "Claude: ... saw" and "You: ... expect" lines. Then close #39 on GitHub.

## Unfinished

- Pull request #85 (`dev-test-changes-note`, one line in CHANGES.md): auto-merge is on; it merges once the checks pass.
- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
- life-admin: set up 2026-11-22 (its pull request #1 merged, work branch `life-test`). The TickTick janitor plan and
  its rulings live there now; continue in a session on that repo.
