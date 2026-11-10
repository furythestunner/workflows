# Questions

## §1 Open questions (only Balázs can answer)

None.

## §2 Rulings

Rulings on the workflow itself, with the date. A ruling that replaces an earlier one edits that entry. Decided by
Balázs on 2026-10-22, from an r/ClaudeCode post ("runs like a small engineering team"); GitHub stays, no GitLab.

- Open work lives in GitHub issues. `BACKLOG.md` keeps only the link, so there is one list.
- `questions.md` stays a file: a ruling is a standing rule, not a task, and a closed issue drops out of sight.
- The check-by tag has one fixed form, `(check by YYYY-MM-DD)`, so the script can read it; other spellings are
  listed as BAD TAG.
- Facts that can go stale live only in `notes/lessons.md`: memories stay on one PC, and a cloud session cannot see
  their dates. Default 3 months, at most 12; a fact the user confirmed also expires, after 12 months.
- The user moves issues to Ready by clicking on GitHub (website or phone app). The guard has no "unlock"
  phrase: a phrase could be copied from a document or an issue comment. Moving down (to Backlog) needs
  no approval, so Claude may do it (Balázs, 22 Oct 2026): anything not in Ready is then the user's signal to look.
- Labels read as plain words, "Status: Ready", "Type: Bug" (Balázs, 22 Oct 2026; until then `status::ready`).
  `labels.sh` renames the old ones, so every issue keeps its status.
- Scheduled runs (Balázs, 22 Oct 2026): a day check every 4 hours asks its questions on the issues, a night build
  after midnight Budapest time builds the approved ones and opens the pull request; a phone notification only
  when something needs the user.
- Done = closed: the pull request says "Closes #<n>" and merging it is the approval. Replaced 2026-11-10: three
  statuses only (Backlog, Ready, In progress). Blocked became "back to Backlog with the question in a comment"
  (Balázs answers and sets Ready again), Review became "stays In progress until the merge", and work with no pull
  request (was `Status: Done`) is closed by Balázs.
- Claude may open issues, always in backlog. An issue with a missing or double label is listed as NEEDS A LABEL,
  never guessed into a status.
- Issues are not shared outside the repo's collaborators for now (the repos are private).
- Decided by Balázs on 2026-10-23: this repo runs the workflow on itself (its own `CLAUDE.md`, handoff and
  trackers); `scripts/check.sh` runs on every pull request; every pull request gets `/code-review` before it opens
  and a watcher after; a weekly drift check (Mondays 07:43 Budapest, phone notification) reports repos on an old
  copy.
- Skills live only in the repos, never uploaded to a claude.ai account (Balázs, 2026-10-23): he works on a personal
  and a company account and does not want to install them on each, and only the repo copy reaches every session.
- Branches (Balázs, 2026-10-23): work goes on the work branch; a second branch only for parallel work, named
  `WORK_BRANCH-<topic>`, and the branch guard blocks any other name. Merged branches are deleted by GitHub
  ("Automatically delete head branches", 2026-10-26), with a ruleset that protects `main` and the work branch from
  deletion (README.md, "Delete merged branches by themselves"; only where GitHub enforces rulesets, so not in the
  private project repos); a cloud session cannot delete branches (GitHub answers 403).
- A pull request that changes only `notes/` skips `/code-review` (Balázs, 2026-11-02; replaced 2026-11-02, same
  day: Claude first recorded the opposite after misreading "3 ok"). Rules, skills, CLAUDE.md and README still get
  the review: they are text files that change how Claude works.
- All 4 project repos stay `released`, none is before v1.0 (Balázs, 2026-11-02): intranet and website go live on a
  merge, KolLab.extension's `main` is the colleagues' release, claude-mods is the only one used by Balázs alone.
  So "building" mode had no user: removed 2026-11-10 (`MERGE_MODE` is no longer read).
- Plugins stay out: plugins a repo's `.claude/settings.json` declares do not load in cloud sessions (Claude Code
  docs, "Settings in cloud sessions", checked 2026-10-23), so the files live in each repo. Confirmed by Balázs on
  2026-11-05, asked whether projects could load the workflow as a plugin or a second repo instead of the sync (a
  second attached repo's rules, skills and hooks do not load either): keep the sync, look again when the cloud
  plugin fact in `.claude/lessons/shared-facts.md` is due (2027-01-23).
- No hand copying (Balázs, 2026-10-23): a GitHub Action syncs the files to the repos as a pull request; each repo
  follows the latest version (merged by the sync itself since 2026-10-26). The shared rules moved out of each CLAUDE.md into
  `.claude/rules/workflow.md`; a project's CLAUDE.md only adds to them. This repo stays on Balázs's personal account.
- Less admin (Balázs, 2026-10-26): Claude closes an issue when Balázs's own message names it ("close #12"; the guard
  reads only his typed message, so an issue comment or a pasted text cannot unlock it). The sync merges its own pull
  requests. Merged branches delete themselves. Nothing new is added to the workflow for now (replaced 2026-11-10
  by the freeze below: 6 hooks and the crew were added after this line, so it now has a check).
- Time estimates are measured (Balázs, 2026-10-26): the estimate check (sent Claude back on every time in a reply)
  is gone; `round-timer.mjs` writes each work round to `notes/rounds.md` and the brief shows the latest. Replaced
  2026-11-10: the timer is gone too. Its 18 rounds took 1 to 15 min each; that range is now one line in
  `.claude/rules/workflow.md`, and the hook no longer costs a commit after every code reply.
- The user's steps go in the chat (Balázs, 2026-10-27): written out in full, never "see README"; the handoff's
  "Waiting for the user" keeps each item's steps. The README sections stay as the reference Claude copies from.
  Replaced 2026-11-02 (#45): each Waiting item is one line starting with 🟡, with full steps only for items added
  at the last handoff update or when asked; the old rule (full steps every brief) buried the answer under a page of
  ignored items. Replaced 2026-11-10: the brief opens the first reply again, at most about 8 short lines (wrong or
  due, Claude next, one 🟡 line each, one proposed task), then a line, then the answer. Balázs: a brief at the end
  meant scrolling up, and it was still too long.
- Claims about the repo are checked (Balázs, 2026-11-10, from a Reddit idea: "cite file:line"): a hook, not a line
  in the rules, because a wrong claim about the code is hard for him to catch. The other ideas from that thread
  were dropped (name the files first, a queue for messages, a weekly proposal run): Claude Code or `/handoff`
  already covers them.
- Five more guards (Balázs, 2026-10-26: "do all improvements and hook suggestions"): checks before a push,
  secrets, a review before a pull request, synced files in project repos, em dashes. `CHECK` stays optional.
- claude-mods joins the sync (Balázs, 2026-10-26): it is an active code project, and its skills come from here like
  every other repo's instead of a personal or plugin copy. Work branch `mods-test`; its `PLAN.md` moves to issues.
- Merges without the click (Balázs, 2026-10-26, #26): agreeing in the chat on what to build is the approval, so a
  pull request merges by itself once its checks pass. Only two-way doors; a one-way door waits for
  him. (Building mode, where every pull request merged, was removed 2026-11-10.) Night runs never merge. Merge commits, not squash: the work branch
  lives on after each merge, and squashed commits would make it conflict with `main`.
- New-session reminder at 300k tokens (Balázs, 2026-11-02): a cloud session starts at about 75k of its 1M window
  (Claude Code's own instructions and tools, about 10k of it this workflow), so the old 150k left only about 75k for
  work, gone in 2 to 3 messages. A repo can still set its own `CONTEXT_WARN`.
- Critical review of the setup (Balázs, 2026-11-10, after Claude's review: 14 hooks, 13 skills, 161 commits in 3
  weeks for one person and 4 repos). His rulings:
  - Cut: the skill hint on every message (`skill-nudge.mjs`; Claude Code picks skills from their descriptions),
    the skills list at session start (#52), the round timer, "building" merge mode, the statuses Blocked, Review
    and Done.
  - Keep: `/crew` and its 3 agents.
  - Cut too, after a fuller explanation (picker answer, same day): the shared-lessons pipeline (the daily
    collector job and `lesson-check.mjs`). Shared lessons are written in the master copy by hand; the 3 lessons
    waiting in pull request #54 were brought in that way.
  - Narrow shared facts moved to `.claude/lessons/shared-facts.md`, read only when needed (#53).
  - An off switch (`.claude/workflow-off`, created by Balázs on GitHub, never by Claude) and a usage record
    (`notes/usage.md`), both in `.claude/hooks/run.mjs`. Tests for `ground-truth.sh` and `session-start.sh`.
  - Trials with an end date: the fact check and the simple-language lines, both judged around 2026-11-17 (the
    fact check by its count in `notes/usage.md` and by how many of its send-backs were false alarms).
- The freeze (Balázs, 2026-11-10): no new hook and no new skill until intranet, KolLab.extension and website are
  on the current workflow and Balázs has checked the brief in each (#44). `scripts/check.sh` enforces the count
  (12 hook files, 13 skills). After the freeze the count stays: a new hook or skill means an old one goes, and raising
  the number needs his OK in the chat.
