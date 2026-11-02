# Measured rounds

Written by `.claude/hooks/round-timer.mjs`: one line per reply that made a code commit, from the
message that started the turn to the end of the reply. Size Claude's own work from these, never by feel.

- 2026-10-26: 15 min, by hand: 4 skills adapted + 1 hook with tests + check script + docs + code review with 8 fixes + pull request (issue #20)
- 2026-10-26: 5 min, by hand: 1 Stop hook with tests + rule + docs
- 2026-10-26: 15 min, by hand: 1 guard change with 15 tests + sync change + README guide + code review with 2 fixes
- 2026-10-27 06:27 UTC: 3 min, 1 commit: The user's steps go in the chat, written out, never "see README"
- 2026-10-27 07:04 UTC: 2 min, 2 commits: Rulesets are not enforced on free private repos: lesson, handoff steps; Round timer: a screenshot alone starts a turn
- 2026-10-27 07:07 UTC: 1 min, 1 commit: Lesson: auto-merge greyed out on free private repos; claude-mods settings done
- 2026-10-27 07:14 UTC: 1 min, 1 commit: Free plan on both accounts: lesson; handoff steps written out
- 2026-10-28 11:49 UTC: 5 min, 2 commits: Hook tests pass on Windows: temp paths converted for node; Crew: file fence, fresh reviewer and smoke list
- 2026-11-01 16:56 UTC: 8 min, 2 commits: Handoff check: also on docs commits, talk and context size; handoff template drops Running and Last session; Handoff check: review fixes ...
- 2026-11-01 18:03 UTC: 3 min, 1 commit: Short brief keeps Next and Waiting when the first message is a task
- 2026-11-02 19:50 UTC: 4 min, 1 commit: New-session reminder at 300k tokens by default; one block per topic in replies
- 2026-11-02 19:57 UTC: 4 min, 1 commit: Brief after the answer, Waiting as one yellow line each; multiple choice through the picker
