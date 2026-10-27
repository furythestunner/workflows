#!/bin/bash
# Tests for push-check.mjs: each case is a CHECK in a scratch repo's ground-truth.conf and a command, and whether
# the hook must block it.
# Usage: bash .claude/hooks/push-check.test.sh   (exit 0 = all pass)
hook=$(cd "$(dirname "$0")" && pwd)/push-check.mjs
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
mkdir -p "$tmp/.claude"
t() { # <block|allow> <CHECK value, or - for none> <command>
  local out got
  if [ "$2" = - ]; then : >"$tmp/.claude/ground-truth.conf"; else printf 'CHECK="%s"\n' "$2" >"$tmp/.claude/ground-truth.conf"; fi
  out=$(node -e 'process.stdout.write(JSON.stringify({tool_name: "Bash", tool_input: {command: process.argv[1]}}))' "$3" |
    CLAUDE_PROJECT_DIR=$tmp node "$hook")
  case $out in *'"deny"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: [$2] $3"; else echo "FAIL  expected $1, got $got: [$2] $3"; fail=1; fi
}
t block 'echo FAIL  one; exit 1' 'git push -u origin dev-test'
t block 'exit 1' 'git add -A && git commit -m x && git push'
t allow 'echo ok; exit 0' 'git push -u origin dev-test'
t allow - 'git push -u origin dev-test'
t allow 'exit 1' 'git push origin --delete old-branch'
t allow 'exit 1' 'git commit -m "then git push"'
t allow 'exit 1' 'git status'
t block 'exit 1' 'date -d now && git push'
t block 'exit 1' 'mkdir -p x && git push origin dev-test'
mkdir -p "$tmp/other/.claude"; echo 'CHECK="exit 0"' >"$tmp/other/.claude/ground-truth.conf"
t allow 'exit 1' 'cd other && git push'
t allow 'exit 1' 'git -C other push'
out=$(printf '{bad' | node "$hook" 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
