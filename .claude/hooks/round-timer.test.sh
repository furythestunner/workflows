#!/bin/bash
# Tests for round-timer.mjs: each case is a scratch repo with commits and a turn that started at a given time; the
# hook must append the expected line to notes/rounds.md (or none) and send Claude back to commit it (or not).
# Usage: bash .claude/hooks/round-timer.test.sh   (exit 0 = all pass)
hook=$(cd "$(dirname "$0")" && pwd)/round-timer.mjs
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
commit() { # <repo> <ISO date> <file> <subject>
  mkdir -p "$1/$(dirname "$3")"; echo "$4" >>"$1/$3"
  git -C "$1" add -A && GIT_AUTHOR_DATE=$2 GIT_COMMITTER_DATE=$2 git -C "$1" -c user.name=t -c user.email=t@t commit -qm "$4"
}
run() { # <repo> <turn start ISO> <stop_hook_active> [origin kind]: prints block or allow
  local f="$1.jsonl"
  printf '%s\n' \
    "{\"type\":\"user\",\"timestamp\":\"$2\",\"origin\":{\"kind\":\"${4:-human}\"},\"message\":{\"content\":\"build it\"}}" \
    '{"type":"user","timestamp":"2026-10-26T10:30:00Z","isMeta":true,"message":{"content":"Stop hook feedback: x"}}' >"$f"
  case $(printf '{"transcript_path":"%s","stop_hook_active":%s,"now":"2026-10-26T10:40:00Z"}' "$f" "$3" |
    CLAUDE_PROJECT_DIR=$1 node "$hook") in *'"block"'*) echo block ;; *) echo allow ;; esac
}
t() { # <name> <expected line, or empty for none> <block|allow> <turn start ISO> <stop_hook_active> <setup> [origin]
  local r="$tmp/$1" got sent
  git init -q "$r"; mkdir -p "$r/.claude"; echo 'DOCS="docs README.md"' >"$r/.claude/ground-truth.conf"
  commit "$r" 2026-10-26T09:00:00Z old.txt "Earlier work"
  $6 "$r"
  sent=$(run "$r" "$4" "$5" "$7")
  got=$(grep '^- ' "$r/notes/rounds.md" 2>/dev/null)
  if [ "$got" = "$2" ] && [ "$sent" = "$3" ]; then echo "ok    $1"
  else echo "FAIL  $1: expected '$2' $3, got '$got' $sent"; fail=1; fi
}
two_code() { commit "$1" 2026-10-26T10:05:00Z a.mjs "Hook A"; commit "$1" 2026-10-26T10:20:00Z a.test.sh "Tests for A"; }
docs_only() { commit "$1" 2026-10-26T10:05:00Z docs/x.md "Docs"; commit "$1" 2026-10-26T10:06:00Z README.md "Readme"; }
bookkeeping() { commit "$1" 2026-10-26T10:05:00Z notes/handoff.md "Handoff"; commit "$1" 2026-10-26T10:06:00Z notes/rounds.md "Measured round"; }
mixed() { commit "$1" 2026-10-26T10:05:00Z docs/x.md "Docs"; commit "$1" 2026-10-26T10:07:00Z b.sh "Script B"; }
none() { :; }
t two-commits '- 2026-10-26 10:00 UTC: 40 min, 2 commits: Hook A; Tests for A' block 2026-10-26T10:00:00Z false two_code
t docs-only '' allow 2026-10-26T10:00:00Z false docs_only
t handoff-and-rounds-only '' allow 2026-10-26T10:00:00Z false bookkeeping
t mixed '- 2026-10-26 10:00 UTC: 40 min, 1 commit: Script B' block 2026-10-26T10:00:00Z false mixed
t no-commit '' allow 2026-10-26T10:00:00Z false none
t github-event-turn '' allow 2026-10-26T10:30:00Z false two_code github
t second-stop-writes-no-send-back '- 2026-10-26 10:00 UTC: 40 min, 2 commits: Hook A; Tests for A' allow 2026-10-26T10:00:00Z true two_code
# The same turn stopping again (another hook sent Claude back): one line, no second send-back.
r="$tmp/again"; git init -q "$r"; commit "$r" 2026-10-26T10:05:00Z a.mjs "Hook A"
run "$r" 2026-10-26T10:00:00Z false >/dev/null; sent=$(run "$r" 2026-10-26T10:00:00Z true)
n=$(grep -c '^- ' "$r/notes/rounds.md")
if [ "$n" = 1 ] && [ "$sent" = allow ]; then echo "ok    same turn twice: one line"; else echo "FAIL  same turn twice: $n lines, $sent"; fail=1; fi
out=$(printf '{bad' | node "$hook" 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
