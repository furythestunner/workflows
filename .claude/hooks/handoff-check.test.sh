#!/bin/bash
# Tests for handoff-check.sh: each case is a scratch clone with a remote, some commits, and whether the hook must
# send Claude back to update the handoff.
# Usage: bash .claude/hooks/handoff-check.test.sh   (exit 0 = all pass)
hook=$(cd "$(dirname "$0")" && pwd)/handoff-check.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
g() { git -C "$r" -c user.name=t -c user.email=t@t "$@"; }
c() { mkdir -p "$r/$(dirname "$1")"; echo x >>"$r/$1"; g add -A; g commit -qm "$1"; }  # <file>: one commit
t() { # <name> <block|allow> <setup commands> [stop_hook_active]
  r="$tmp/$1"
  git init -q --bare "$r.git"; git init -q -b work "$r"; g remote add origin "$r.git"
  mkdir -p "$r/.claude"; echo 'WORK_BRANCH="work" HANDOFF="notes/handoff.md" DOCS="notes README.md"' >"$r/.claude/ground-truth.conf"
  c code.sh; c notes/handoff.md; g push -q -u origin work 2>/dev/null
  eval "$3"
  local out got
  out=$(printf '{"stop_hook_active":%s}' "${4:-false}" | CLAUDE_PROJECT_DIR=$r bash "$hook")
  case $out in *'"block"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$2" ]; then echo "ok    $2: $1"; else echo "FAIL  expected $2, got $got: $1"; fail=1; fi
}
t code-pushed-after-handoff block 'c app.sh; g push -q'
t code-not-pushed allow 'c app.sh'
t docs-only-after-handoff allow 'c README.md; c notes/x.md; g push -q'
t handoff-newer allow 'c app.sh; c notes/handoff.md; g push -q'
t other-branch allow 'g checkout -q -b other; c app.sh; g push -q -u origin other 2>/dev/null'
t second-stop allow 'c app.sh; g push -q' true
exit $fail
