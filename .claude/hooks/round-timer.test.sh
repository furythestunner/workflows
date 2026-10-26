#!/bin/bash
# Tests for round-timer.mjs: each case is a scratch repo with commits, a turn that started at a given time, and
# the line the hook must append to notes/rounds.md (or that it must append nothing).
# Usage: bash .claude/hooks/round-timer.test.sh   (exit 0 = all pass)
hook=$(cd "$(dirname "$0")" && pwd)/round-timer.mjs
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
commit() { # <repo> <ISO date> <file> <subject>
  mkdir -p "$1/$(dirname "$3")"; echo "$4" >>"$1/$3"
  git -C "$1" add -A && GIT_AUTHOR_DATE=$2 GIT_COMMITTER_DATE=$2 git -C "$1" -c user.name=t -c user.email=t@t commit -qm "$4"
}
t() { # <name> <expected line, or empty for none> <turn start ISO> <stop_hook_active> <setup function>
  local r="$tmp/$1" f="$tmp/$1.jsonl" got
  git init -q "$r"; mkdir -p "$r/.claude"; echo 'DOCS="notes README.md"' >"$r/.claude/ground-truth.conf"
  commit "$r" 2026-10-26T09:00:00Z old.txt "Earlier work"
  $5 "$r"
  printf '%s\n' \
    "{\"type\":\"user\",\"timestamp\":\"$3\",\"origin\":{\"kind\":\"human\"},\"message\":{\"content\":\"build it\"}}" \
    '{"type":"user","timestamp":"2026-10-26T10:30:00Z","isMeta":true,"message":{"content":"Stop hook feedback: x"}}' >"$f"
  printf '{"transcript_path":"%s","stop_hook_active":%s,"now":"2026-10-26T10:40:00Z"}' "$f" "$4" |
    CLAUDE_PROJECT_DIR=$r node "$hook"
  got=$(grep '^- ' "$r/notes/rounds.md" 2>/dev/null)
  if [ "$got" = "$2" ]; then echo "ok    $1"; else echo "FAIL  $1: expected '$2', got '$got'"; fail=1; fi
}
two_code() { commit "$1" 2026-10-26T10:05:00Z a.mjs "Hook A"; commit "$1" 2026-10-26T10:20:00Z a.test.sh "Tests for A"; }
docs_only() { commit "$1" 2026-10-26T10:05:00Z notes/handoff.md "Handoff"; commit "$1" 2026-10-26T10:06:00Z README.md "Docs"; }
mixed() { commit "$1" 2026-10-26T10:05:00Z notes/handoff.md "Handoff"; commit "$1" 2026-10-26T10:07:00Z b.sh "Script B"; }
none() { :; }
t two-commits '- 2026-10-26: 40 min, 2 commits: Hook A; Tests for A' 2026-10-26T10:00:00Z false two_code
t docs-only '' 2026-10-26T10:00:00Z false docs_only
t mixed '- 2026-10-26: 40 min, 1 commit: Script B' 2026-10-26T10:00:00Z false mixed
t no-commit '' 2026-10-26T10:00:00Z false none
t second-stop '' 2026-10-26T10:00:00Z true two_code
out=$(printf '{bad' | node "$hook" 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
