#!/bin/bash
# Tests for fence.sh: each case is a scratch repo with one committed file set, a round record with a "Files:" line,
# some changes, and whether the fence must pass or stop.
# Usage: bash .claude/skills/crew/fence.test.sh   (exit 0 = all pass)
fence=$(cd "$(dirname "$0")" && pwd)/fence.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
g() { git -C "$r" -c user.name=t -c user.email=t@t -c core.autocrlf=false "$@"; }
w() { mkdir -p "$r/$(dirname "$1")"; echo y >>"$r/$1"; }  # <file>: change or create it
t() { # <name> <pass|stop|nofence> <Files line> <changes>
  r="$tmp/$1"
  git init -q "$r"
  for f in app/a.js app/b.js lib/c.js "docs/my notes.md" README.md; do w "$f"; done
  g add -A; g commit -qm base
  mkdir -p "$r/notes/crew"; printf '# Round\n%s\n' "$3" >"$r/notes/crew/round.md"
  eval "$4"
  local got
  (cd "$r" && bash "$fence" notes/crew/round.md >/dev/null 2>&1); case $? in 0) got=pass ;; 1) got=stop ;; *) got=nofence ;; esac
  if [ "$got" = "$2" ]; then echo "ok    $2: $1"; else echo "FAIL  expected $2, got $got: $1"; fail=1; fi
}
t inside pass 'Files: app/a.js, lib/c.js' 'w app/a.js; w lib/c.js'
t outside stop 'Files: app/a.js' 'w app/a.js; w README.md'
t new-file-outside stop 'Files: app/a.js' 'w app/new.js'
t folder pass 'Files: app/' 'w app/a.js; w app/new/deep.js'
t folder-prefix-only stop 'Files: app/' 'w lib/c.js'
t glob pass 'Files: app/*.js' 'w app/b.js'
t backticks-and-cr pass "$(printf 'Files: `app/a.js` `lib/c.js`\r')" 'w lib/c.js'
t space-in-path pass 'Files: docs/' 'w "docs/my notes.md"'
t deleted-outside stop 'Files: app/a.js' 'rm "$r/README.md"'
t renamed-from-outside stop 'Files: app/' 'g mv README.md app/README.md'
t record-itself-allowed pass 'Files: app/a.js' 'w notes/crew/other.md'
t indented-in-brief pass '  Files: app/a.js' 'w app/a.js'
t no-files-line nofence 'Spec: something' 'w app/a.js'
t nothing-changed pass 'Files: app/a.js' ':'
exit $fail
