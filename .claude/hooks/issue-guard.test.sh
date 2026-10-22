#!/bin/bash
# Tests for issue-guard.mjs: each case is a tool call and whether the guard must block it.
# Usage: bash .claude/hooks/issue-guard.test.sh   (exit 0 = all pass)
cd "$(dirname "$0")" || exit 1
fail=0
t() { # <block|allow> <tool name> <tool_input JSON>
  local out got
  out=$(printf '{"tool_name":"%s","tool_input":%s}' "$2" "$3" | node issue-guard.mjs)
  case $out in *'"deny"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: $2 $3"; else echo "FAIL  expected $1, got $got: $2 $3"; fail=1; fi
}
gh=mcp__github__issue_write
t block "$gh" '{"method":"update","issue_number":3,"labels":["type::bug","status::ready"]}'
t block "$gh" '{"method":"update","issue_number":3,"labels":["type::bug","status::done"]}'
t block "$gh" '{"method":"update","issue_number":3,"state":"closed","state_reason":"completed"}'
t block "$gh" '{"method":"create","title":"x","labels":["type::bug","status::ready"]}'
t block "$gh" '{"method":"create","title":"x","labels":["type::bug"]}'
t allow "$gh" '{"method":"create","title":"x","labels":["type::bug","status::backlog"]}'
t allow "$gh" '{"method":"update","issue_number":3,"labels":["type::bug","status::in-progress"]}'
t allow "$gh" '{"method":"update","issue_number":3,"labels":["type::bug","status::blocked"]}'
t allow "$gh" '{"method":"update","issue_number":3,"labels":["type::bug","status::review"]}'
t allow mcp__github__add_issue_comment '{"issue_number":3,"body":"Could you move this to status::ready?"}'
t allow mcp__github__list_issues '{"labels":["status::ready"]}'
t block Bash '{"command":"gh issue close 3"}'
t block Bash '{"command":"gh issue edit 3 --add-label status::ready --remove-label status::backlog"}'
t block Bash '{"command":"gh issue edit 3 --add-label \"type::bug,status::done\""}'
t allow Bash '{"command":"gh issue edit 3 --add-label status::in-progress --remove-label status::ready"}'
t block Bash '{"command":"gh issue create -t x -b y --label type::bug"}'
t allow Bash '{"command":"gh issue create -t x -b y --label type::bug --label status::backlog"}'
t block Bash '{"command":"gh api -X PATCH repos/o/r/issues/3 -f state=closed"}'
t block Bash '{"command":"gh api repos/o/r/issues/3/labels -f labels[]=status::ready"}'
t block Bash '{"command":"gh api -X PUT repos/o/r/issues/3/labels -f labels[]=status%3A%3Adone"}'
t allow Bash '{"command":"gh api -X DELETE repos/o/r/issues/3/labels/status::ready"}'
t block Bash '{"command":"gh api -X DELETE repos/o/r/labels/status::ready"}'
t block Bash '{"command":"gh label delete status::done --yes"}'
t allow Bash '{"command":"gh api \"repos/o/r/issues?labels=status::ready\""}'
t allow Bash '{"command":"gh api repos/o/r/issues/3/labels -f labels[]=status::in-progress"}'
t allow Bash '{"command":"bash .claude/skills/session-start/labels.sh"}'
t allow Bash '{"command":"git commit -m \"Guard: blocks gh issue close and status::ready\""}'
t block Bash '{"command":"cd /x && gh issue close 3"}'
t block Bash '{"command":"echo $(gh api -X PATCH repos/o/r/issues/3 -f state=closed)"}'
exit $fail
