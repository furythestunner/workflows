#!/bin/bash
# Tests for branch-guard.mjs: each case is a tool call in a scratch repo whose work branch is "app-test", and whether
# the guard must block it.
# Usage: bash .claude/hooks/branch-guard.test.sh   (exit 0 = all pass)
cd "$(dirname "$0")" || exit 1
here=$(pwd)
repo=$(mktemp -d); other=$(mktemp -d); trap 'rm -rf "$repo" "$other"' EXIT
git init -q -b app-test "$repo" && git init -q -b main "$other"
mkdir -p "$repo/.claude"
printf 'REPOS=("app|.|origin|main|acme/app")\nWORK_BRANCH="app-test"\n' > "$repo/.claude/ground-truth.conf"
git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C "$repo" tag v1.0
fail=0
t() { # <block|allow> <tool name> <tool_input JSON> [cwd]
  local out got
  out=$(printf '{"tool_name":"%s","tool_input":%s,"cwd":"%s"}' "$2" "$3" "${4:-$repo}" |
    CLAUDE_PROJECT_DIR="$repo" node "$here/branch-guard.mjs")
  case $out in *'"deny"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: $2 $3"; else echo "FAIL  expected $1, got $got: $2 $3"; fail=1; fi
}
t allow Bash '{"command":"git push -u origin app-test"}'
t allow Bash '{"command":"git push"}'
t allow Bash '{"command":"git push origin HEAD"}'
t allow Bash '{"command":"git checkout -b app-test-leave-totals"}'
t allow Bash '{"command":"git switch -c app-test-fix"}'
t allow Bash '{"command":"git push -u origin app-test-leave-totals"}'
t allow Bash '{"command":"git push origin HEAD:app-test-a-b-c-d"}'
t allow Bash '{"command":"git push origin workflow-sync"}'
t allow Bash '{"command":"git checkout -b app-test origin/app-test"}'
t block Bash '{"command":"git checkout -b leave-totals"}'
t block Bash '{"command":"git checkout -b claude/optimistic-albattani-9qi8q5"}'
t block Bash '{"command":"git switch -c fix/leave"}'
t block Bash '{"command":"git branch cache-clock-working"}'
t block Bash '{"command":"git worktree add -b quick-fix ../x"}'
t block Bash '{"command":"git push -u origin claude/festive-carson-ojagt8"}'
t block Bash '{"command":"git push origin HEAD:refs/heads/random-name"}'
t block Bash '{"command":"git push origin app-test-Leave_Totals"}'
t block Bash '{"command":"git push origin app-test-one-two-three-four-five"}'
t block Bash '{"command":"git push origin app-test-"}'
t block Bash '{"command":"git push origin main"}'
t block Bash "{\"command\":\"cd $repo && git checkout -b wip\"}" /
t block Bash "{\"command\":\"git -C $repo push origin wip\"}" /
t allow Bash '{"command":"git push origin --delete cache-clock-working"}'
t allow Bash '{"command":"git push origin :cache-clock-working"}'
t allow Bash '{"command":"git branch -d wip"}'
t allow Bash '{"command":"git branch --show-current"}'
t allow Bash '{"command":"git push origin v1.0 refs/tags/v1.0"}'
t allow Bash '{"command":"git commit -m \"Guard: git checkout -b wip is blocked; git push origin wip too\""}'
t allow Bash '{"command":"git checkout -b wip"}' "$other"
t allow mcp__github__create_branch '{"owner":"acme","repo":"app","branch":"app-test-sheet-export","from_branch":"main"}'
t block mcp__github__create_branch '{"owner":"acme","repo":"app","branch":"sheet-export","from_branch":"main"}'
t allow mcp__github__create_branch '{"owner":"acme","repo":"elsewhere","branch":"anything"}'
# The current branch is pushed when no branch is named: a cloud session's own branch is caught too.
git -C "$repo" checkout -q -b claude/vigilant-babbage-piirsk
t block Bash '{"command":"git push -u origin"}'
t block Bash '{"command":"git push origin HEAD"}'
# Since 26 Oct 2026 (code review of issue #20): redirections, $( ), env prefixes, --orphan, worktree add without -b.
git -C "$repo" checkout -q app-test
t allow Bash '{"command":"git push -u origin app-test 2>&1 | tail -3"}'
t allow Bash '{"command":"git push origin app-test >/dev/null 2>/dev/null"}'
t allow Bash '{"command":"git branch 2>/dev/null"}'
t allow Bash '{"command":"git push origin $(git branch --show-current)"}'
t block Bash '{"command":"git push origin wip 2>&1"}'
t block Bash '{"command":"GIT_TRACE=0 git push origin junk"}'
t block Bash '{"command":"command git push origin junk"}'
t block Bash '{"command":"git checkout --orphan junk"}'
t block Bash '{"command":"git worktree add ../quick-fix"}'
t allow Bash '{"command":"git worktree add ../app-test-docs"}'
t allow Bash '{"command":"git worktree add --detach ../x"}'
t allow Bash '{"command":"git worktree add ../x app-test"}'
t allow mcp__github__create_branch '{"owner":"acme","repo":"ap","branch":"anything"}'
exit $fail
