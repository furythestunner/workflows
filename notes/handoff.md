# Handoff

Updated: 2026-11-22 (todo system planning started in the chat; no build yet, Balázs: "dont build anything yet,
still planning")

## Next (Claude's own work, nothing for you)

1. Shared lessons are collected by hand now: when Balázs says "collect the shared lessons", read the "## Shared"
   section of each project repo's `notes/lessons.md` and write them into the two shared files here.
2. Fact check trial (`fact-check.mjs`, due since 2026-11-17; simple language was decided 2026-11-19): it never
   fired in this repo. Read its count in each project repo's `notes/usage.md` (attach them read-only), then ask
   Balázs: keep or cut.
3. Old status labels: in a session where `gh` is logged in (the PC), run
   `bash .claude/skills/session-start/labels.sh` in this repo; it moves issues out of Blocked and Review and
   deletes those labels. In the project repos only after asking Balázs.
4. Upload checks: intranet, website and KolLab.extension are on (2026-11-02). claude-mods waits for the PC test run
   below: in the cloud 20 tests fail in cache-clock and skill-picker, all built around Windows paths (C:/...);
   if they pass on the PC, the cloud is the cause and the check needs a cloud skip.

## Waiting for Balázs (your steps)

- 🟡 Check the brief in each project (added 2026-11-02, about 2 min each; the 4 sync pull requests were merged 2026-11-10):
  on claude.ai/code start a new session, pick the repo (intranet, then KolLab.extension, then website), set the
  branch to its work branch (`intra-test`, `extension-test`, `website-test`) and send a short question. The reply
  should open with the brief (about 8 lines, your open steps as one 🟡 line each), then a line, then the answer. If
  not, say which repo in the chat. This also ends the freeze (issue #44).
- 🟡 Run the claude-mods tests on your PC (added 2026-11-02, about 2 min): Start menu, type `Git Bash`, open it,
  type `cd /c/GitHub/claude-mods` and Enter, then `claude plugin test mods/cache-clock` and Enter, then
  `claude plugin test mods/skill-picker` and Enter. Paste the last 2 lines of each into the chat.
- 🟡 TickTick connector test (added 2026-11-22, about 8 min; for the todo system plan below): open TickTick on
  the PC, go to NOTES > IMPORTANT, copy each login into your password manager, delete them from the note. Then
  on claude.ai: Settings, Connectors, "Add custom connector", name `TickTick`, URL `https://mcp.ticktick.com`,
  Add, Connect, sign in to TickTick, Allow. On the phone Claude app say "Add a TickTick task: test task, due
  tomorrow" and check it shows in TickTick. Paste the result in the chat.
- 🟡 Try one short `/crew` round, issue #39 (added 2026-10-28, about 10 min): in a project repo with a Ready issue,
  after the sync pull request is merged, type `/crew`, approve the brief, and at the end check that the report has a
  test list with "Claude: ... saw" and "You: ... expect" lines. Then close #39 on GitHub.

## Unfinished

- claude-mods `mods-test`: its new work branch, with the branch rule in CLAUDE.md; not on `main` yet.
- Todo system plan (2026-11-22), only in the chat so far; it gets its own repo, not this one. Decided: TickTick
  stays (official connector, untested); personal and family only, work stays in M365 Planner; dictate in the
  phone Claude app, Claude picks the list (dated tasks to EVENTS); a daily run reads Gmail (sent mail and order
  mails), ticks matched tasks off and names them in a morning summary; the May 21 TickTick structure stays
  (lists, #health and #wait, the TO-DO board). Open: default list for undated tasks, which senders count as
  proof, summary time and channel, dictation language, repo name. Nothing is built until Balázs says "build".
  Android phone, budget about €5/month. App comparison (2026-11-22, Balázs not yet convinced about TickTick):
  https://claude.ai/artifact/YSgMfysifKWzJFaqHoqhC4 (now out of date: Todoist was rejected in an earlier chat).
  From Balázs's pasted briefing (2026-11-22): Claude is the "janitor": you dump notes into the TickTick Inbox
  (or tell Claude), Claude sorts, removes duplicates, flags stale items; a short digest every day; the first
  cleanup pass only proposes and waits for OK. Connector: jacepark12/ticktick-mcp is installed on the PC
  (Claude Code, user scope, no refresh token), never tested live; it cannot serve the phone or a cloud run.
  Next: the same 6-check test on it and on TickTick's own server (mcp.ticktick.com), keep the one that can
  move and delete. The TickTick client secret showed in a screenshot: make a new one.
