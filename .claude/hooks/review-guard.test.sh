#!/bin/bash
# Tests for review-guard.mjs: each case is a transcript and a tool call, and whether the guard must block it.
# Usage: bash .claude/hooks/review-guard.test.sh   (exit 0 = all pass)
cd "$(dirname "$0")" || exit 1
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
command -v cygpath >/dev/null && tmp=$(cygpath -m "$tmp") # node on Windows needs C:/...
fail=0
none='{"type":"user","message":{"content":"open the PR"}}'
skill='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"code-review","args":"main...HEAD"}}]}}'
typed='{"type":"user","message":{"content":"<command-name>/code-review</command-name>"}}'
mention='{"type":"user","message":{"content":"did you run code-review?"}}'
t() { # <block|allow> <transcript line> <tool> <tool_input JSON>
  local out got
  echo "$2" >"$tmp/t.jsonl"
  out=$(printf '{"tool_name":"%s","tool_input":%s,"transcript_path":"%s","tool_use_id":"t2"}' "$3" "$4" "$tmp/t.jsonl" | node review-guard.mjs)
  case $out in *'"deny"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: $3 $4"; else echo "FAIL  expected $1, got $got: $3 $4 after $2"; fail=1; fi
}
pr=mcp__github__create_pull_request
t block "$none" $pr '{"title":"x"}'
t block "$mention" $pr '{"title":"x"}'
t block "$none" Bash '{"command":"gh pr create -t x -b y"}'
t allow "$skill" $pr '{"title":"x"}'
t allow "$typed" Bash '{"command":"gh pr create -t x -b y"}'
t allow "$none" Bash '{"command":"git commit -m \"gh pr create next\""}'
t allow "$none" mcp__github__list_pull_requests '{}'
opened='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"t1","name":"mcp__github__create_pull_request","input":{"title":"first"}}]}}'
now='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"t2","name":"mcp__github__create_pull_request","input":{"title":"second"}}]}}'
t block "$skill"$'\n'"$opened" $pr '{"title":"second"}'
t allow "$skill"$'\n'"$opened"$'\n'"$skill" $pr '{"title":"second"}'
t allow "$skill"$'\n'"$now" $pr '{"title":"second"}'
out=$(printf '{bad' | node review-guard.mjs 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
