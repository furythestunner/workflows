# Handoff

Updated: 2026-11-10 (critical review of the setup, then the cuts: 2 hooks, the skills list at start, building
mode, 3 statuses, the shared-lessons pipeline; new: off switch, usage record, narrow facts file, tests for the ground truth; the freeze)

## Next (Claude's own work, nothing for you)

1. After the merge of the review's pull request (#61, merged 2026-11-10 after Balázs's "brief ok"): the sync opens
   a pull request in each of the 4 project repos. Check that all 4 exist and give Balázs the links (they are not
   visible from a workflows cloud session: ask him to paste what he sees if one is missing).
2. Shared lessons are collected by hand now: when Balázs says "collect the shared lessons", read the "## Shared"
   section of each project repo's `notes/lessons.md` and write them into the two shared files here.
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

- 🟡 Merge the 4 sync pull requests (added 2026-11-10, about 1 min each): they wait for a click this time, because
  they remove files. For each repo open its pull request list: https://github.com/Kol-Lab-Design-Kft/intranet/pulls,
  https://github.com/Kol-Lab-Design-Kft/KolLab.extension/pulls, https://github.com/Kol-Lab-Design-Kft/website/pulls,
  https://github.com/furythestunner/claude-mods/pulls. Click the pull request from the branch `workflow-sync`,
  scroll down, click "Merge pull request", then "Confirm merge". Nothing else to do under "Do before merging".
- 🟡 Check the brief in each project (added 2026-11-02, about 2 min each; do it after the step above):
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
- 🟡 Close pull request #54 (added 2026-11-10, about 1 min): its 3 lessons are in the files now. Open
  https://github.com/furythestunner/workflows/pull/54, scroll down, click "Close pull request".
- 🟡 Close issue #35 (added 2026-11-10, about 1 min): it repeats this list. Open
  https://github.com/furythestunner/workflows/issues/35, scroll down, click "Close issue". Or write "close #35".

## Unfinished

- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
