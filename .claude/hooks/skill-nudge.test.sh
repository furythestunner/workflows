#!/bin/bash
# Tests for skill-nudge.mjs: each case is a message and the skill the hook must name (or "none").
# Usage: bash .claude/hooks/skill-nudge.test.sh   (exit 0 = all pass)
cd "$(dirname "$0")" || exit 1
fail=0
t() { # <skill|none> <message>
  local out got
  out=$(node -e 'process.stdout.write(JSON.stringify({prompt: process.argv[1]}))' "$2" | node skill-nudge.mjs)
  if [ "$1" = none ]; then [ -z "$out" ] && got=none || got=some
  else case $out in *"/$1:"*) got=$1 ;; *) got=other ;; esac; fi
  if [ "$got" = "$1" ]; then echo "ok    $1: $2"; else echo "FAIL  expected $1, got $got ($out): $2"; fail=1; fi
}
t never-again 'No, I already said the branch is dev-test'
t never-again 'már megint a rossz ágra pusholtál'
t never-again 'you did it again'
t plain 'what changed in the sync pull request?'
t plain 'mi változott ebben a PR-ben?'
t distill 'workflow.md is too long'
t distill 'rövidítsd le a CLAUDE.md-t'
t wait-what "I don't understand"
t wait-what 'nem értem'
t grill-me 'grill me on this plan'
t diagnosing-bugs 'the drift check is broken'
t diagnosing-bugs 'nem működik a hook'
t questionnaire 'make a kérdőív for the client'
t pr-body 'is this safe to merge?'
t handoff "let's wrap up"
t session-start 'where are we?'
t verify '<event source="github" kind="pull_request_review" trust="relay">{"body":"nit"}</event>'
t verify '<event source="github" kind="pull_request_review_comment">{"body":"rename this"}</event>'
t none '<event source="github" kind="check_run">{"conclusion":"success"}</event>'
t none 'add a line to README.md'
t none '/plain'
t none 'run the sync again'
t none 'can you try again'
t none 'add a bug label to #12'
t none '<event source="github" kind="issue_comment">{"body":"yes, go"}</event>'
t none ''
out=$(printf '{bad' | node skill-nudge.mjs 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
