# Handoff

Updated: 2026-11-10 (critical review of the setup, then the cuts: 2 hooks, the skills list at start, building
mode, 3 statuses; new: off switch, usage record, narrow facts file, tests for the ground truth; the freeze)

## Next (Claude's own work, nothing for you)

1. The review's pull request (dev-test to `main`): merge it only after Balázs's new-session test below passes.
   It is the first change where every hook starts through `.claude/hooks/run.mjs`.
2. Shared-lessons pipeline (`questions.md` §1): explained in the chat on 2026-11-10; cut or keep when Balázs says.
3. Around 2026-11-17, ask Balázs about the two trials. Simple language (this repo's CLAUDE.md): yes, move the
   lines to `.claude/rules/workflow.md` (76 of 80 lines); no, remove them. Fact check (`fact-check.mjs`): read its
   count in `notes/usage.md` and how many send-backs were false alarms; keep or cut.
4. Old status labels: in a session where `gh` is logged in (the PC), run
   `bash .claude/skills/session-start/labels.sh` in this repo; it moves issues out of Blocked and Review and
   deletes those labels. In the project repos only after asking Balázs.
5. Upload checks: intranet, website and KolLab.extension are on (2026-11-02). claude-mods waits for the PC test run
   below: in the cloud 20 tests fail in cache-clock and skill-picker, all built around Windows paths (C:/...);
   if they pass on the PC, the cloud is the cause and the check needs a cloud skip.

## Waiting for Balázs (your steps)

- 🟡 Test the new session start (added 2026-11-10, about 2 min): on claude.ai/code start a new session, pick the
  repo `workflows`, set the branch to `dev-test`, send "where are we?". The reply must open with the brief (about
  8 lines), then a line, then the answer. Say "brief ok" or paste what came instead. Claude merges the pull request
  after that.
- 🟡 Check the brief in each project (added 2026-11-02, about 2 min each; do it after the step above and the merge):
  on claude.ai/code start a new session, pick the repo (intranet, then KolLab.extension, then website), set the
  branch to its work branch (`intra-test`, `extension-test`, `website-test`) and send a short question. The reply
  should open with the brief (about 8 lines, your open steps as one 🟡 line each), then a line, then the answer. If
  not, say which repo in the chat. This also ends the freeze (issue #44).
- 🟡 Run the claude-mods tests on your PC (added 2026-11-02, about 2 min): Start menu, type `Git Bash`, open it,
  type `cd /c/GitHub/claude-mods` and Enter, then `claude plugin test mods/cache-clock` and Enter, then
  `claude plugin test mods/skill-picker` and Enter. Paste the last 2 lines of each into the chat.
- 🟡 Try one short `/crew` round, issue #39 (added 2026-10-28, about 10 min): in a project repo with a Ready issue,
  after the sync pull request is merged, type `/crew`, approve the brief, and at the end check that the report has a
  test list with "Claude: ... saw" and "You: ... expect" lines. Then close #39 on GitHub.
- 🟡 Paste the setup script again (added 2026-11-10, about 2 min, after the merge): open
  https://github.com/furythestunner/workflows/blob/main/cloud/setup-script.sh, click the copy icon ("Copy raw
  file"). On claude.ai/code open a session, click the environment name in the title bar, Edit, select all text in
  the "Setup script" box, paste, Save. Only sessions with several repos need it (the off switch there).
- 🟡 Close issue #35 (added 2026-11-10, about 1 min): it repeats this list. Open
  https://github.com/furythestunner/workflows/issues/35, scroll down, click "Close issue". Or write "close #35".

## Unfinished

- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
