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

# Check 2: no new work behind a merged pull request. A scratch repo whose work branch app-test had pull request #5,
# merged into main; a stand-in for gh answers with the pull requests in FAKE_PRS (or fails when FAKE_PRS=fail).
repo="$tmp/repo"; bare="$tmp/origin.git"
command -v cygpath >/dev/null && { repo=$(cygpath -m "$repo"); bare=$(cygpath -m "$bare"); }
fake="$repo-gh.mjs"
cat >"$fake" <<'JS'
import { writeFileSync } from 'node:fs';
writeFileSync(process.env.FAKE_ARGS, process.argv.slice(2).join(' '));
if (process.env.FAKE_PRS === 'fail') process.exit(1);
process.stdout.write(process.env.FAKE_PRS);
JS
g() { git -C "$repo" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
git init -q --bare -b main "$bare" && git init -q -b main "$repo"
mkdir -p "$repo/.claude" "$repo/notes" "$repo/src"
printf 'REPOS=("app|.|origin|main|acme/app")\nWORK_BRANCH="app-test"\nDOCS="notes README.md"\n' >"$repo/.claude/ground-truth.conf"
echo a >"$repo/README.md"; g add -A; g commit -m init; g remote add origin "$bare"; g push -u origin main
g checkout -b app-test; echo 1 >"$repo/src/one.js"; g add -A; g commit -m one; g push -u origin app-test
round1=$(git -C "$repo" rev-parse HEAD)
g checkout main; g merge --no-ff -m "Merge #5" app-test; g push origin main; g checkout app-test
MERGED='[{"number":5,"state":"closed","merged_at":"2026-11-23T10:00:00Z","base":{"ref":"main"},"head":{"sha":"'$round1'"}}]'
OPEN='[{"number":6,"state":"open","merged_at":null,"base":{"ref":"main"},"head":{"sha":"x"}},'${MERGED:1}
CLOSED='[{"number":6,"state":"closed","merged_at":null,"base":{"ref":"main"},"head":{"sha":"x"}},'${MERGED:1}
new_pr='gh pr'' create' # split, so the review guard does not take this file's text for a real pull request
m() { # <block|allow> <FAKE_PRS> <command>
  local out got
  out=$(node -e 'process.stdout.write(JSON.stringify({tool_name: "Bash", tool_input: {command: process.argv[1]}}))' "$3" |
    CLAUDE_PROJECT_DIR=$repo PUSH_CHECK_GH=$fake FAKE_PRS=$2 FAKE_ARGS=$tmp/args node "$hook")
  case $out in *'"deny"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: [${2:0:30}] $3"; else echo "FAIL  expected $1, got $got: [${2:0:30}] $3 $out"; fail=1; fi
}
m allow "$MERGED" 'git push'
case $(cat "$tmp/args") in *'repos/acme/app/pulls?state=all&head=acme:app-test'*) echo "ok    asks GitHub for app-test's pull requests" ;;
  *) echo "FAIL  gh asked: $(cat "$tmp/args")"; fail=1 ;; esac
echo n >"$repo/notes/handoff.md"; g add -A; g commit -m handoff
m allow "$MERGED" 'git push'
echo 2 >"$repo/src/two.js"; g add -A; g commit -m two
m block "$MERGED" 'git push'
m block "$MERGED" 'git push -u origin app-test'
m block "$MERGED" 'git push origin HEAD:refs/heads/app-test'
m allow "$MERGED" "git push -u origin app-test && $new_pr --base main --head app-test --title x"
m allow "$OPEN" 'git push'
m allow "$CLOSED" 'git push'
m allow '[]' 'git push'
m allow fail 'git push'
m allow 'not json' 'git push'
m allow "$MERGED" 'git push origin HEAD:app-test-other'
m allow "$MERGED" 'git push origin --delete app-test'
g reset --hard HEAD~1
echo 3 >"$repo/src/three.js"; echo z >"$repo/notes/z.md"
m allow "$MERGED" 'git add notes/z.md && git commit -m z && git push'
m block "$MERGED" 'git add src/three.js notes/z.md && git commit -m z && git push'
m block "$MERGED" 'git add -A && git commit -m z && git push'
m allow "$MERGED" 'git add notes && git commit -m z && git push'
rm "$repo/src/three.js"; echo i >"$repo/notes/Iván.md"
m allow "$MERGED" 'git add -A && git commit -m z && git push'
m allow "$MERGED" "git add -A && git commit -m z && git push && GH_REPO=acme/app $new_pr --title x"
rm "$repo/notes/z.md" "$repo/notes/Iván.md"
g checkout main; echo m >"$repo/src/main.js"; g add -A; g commit -m main; g push origin main; g checkout app-test
g merge --no-ff -m "Merge main" main
m allow "$MERGED" 'git push'
g checkout -b side; echo 4 >"$repo/src/four.js"; g add -A; g commit -m four
m allow "$MERGED" 'git push origin side:app-test-four'
m block "$MERGED" 'git push origin side:app-test'
m allow "$MERGED" 'git push origin side'
exit $fail
