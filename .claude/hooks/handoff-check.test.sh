#!/bin/bash
# Tests for handoff-check.sh: each case is a scratch clone with a remote, some commits, an optional transcript, and
# whether the hook must send Claude back.
# Usage: bash .claude/hooks/handoff-check.test.sh   (exit 0 = all pass)
hook=$(cd "$(dirname "$0")" && pwd)/handoff-check.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
g() { git -C "$r" -c user.name=t -c user.email=t@t "$@"; }
c() { mkdir -p "$r/$(dirname "$1")"; echo x >>"$r/$1"; g add -A; g commit -qm "$1"; }  # <file>: one commit
# Transcript lines. user <n> [year]: n typed messages (year 2099 = after the handoff, 2000 = before); ctx <tokens>.
user() { for _ in $(seq "$1"); do y=${2:-2099}; [ ${#y} = 4 ] && y=$y-01-01T00:00:00; printf '{"type":"user","message":{"content":"hi"},"timestamp":"%sZ"}\n' "$y"; done >>"$tx"; }
tool() { echo '{"type":"user","message":{"content":[{"type":"tool_result","content":"x"}]},"timestamp":"2099-01-01T00:00:00Z"}' >>"$tx"; }
ctx() { printf '{"type":"assistant","message":{"usage":{"input_tokens":2,"cache_read_input_tokens":%s,"cache_creation_input_tokens":0}}}\n' "$(($1 - 2))" >>"$tx"; }
run() { # <expected block|allow> <name>: runs the hook on the current case
  local out got
  out=$(printf '{"stop_hook_active":%s,"transcript_path":"%s"}' "${active:-false}" "$tx" | CLAUDE_PROJECT_DIR=$r bash "$hook")
  case $out in *'"block"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: $2"; else echo "FAIL  expected $1, got $got: $2"; fail=1; fi
}
t() { # <name> <block|allow> <setup commands> [stop_hook_active]
  r="$tmp/$1" tx="$tmp/$1.jsonl"; : >"$tx"
  git init -q --bare "$r.git"; git init -q -b work "$r"; g remote add origin "$r.git"
  mkdir -p "$r/.claude"; echo 'WORK_BRANCH="work" HANDOFF="notes/handoff.md" CONTEXT_WARN=150000' >"$r/.claude/ground-truth.conf"
  c code.sh; c notes/handoff.md; g push -q -u origin work 2>/dev/null
  eval "$3"
  active=${4:-false} run "$2" "$1"
}
# Pushed commits newer than the handoff.
t code-pushed-after-handoff block 'c app.sh; g push -q'
t docs-pushed-after-handoff block 'c notes/x.md; g push -q'
t code-not-pushed allow 'c app.sh'
t rounds-only-after-handoff allow 'c notes/rounds.md; g push -q'
t handoff-newer allow 'c app.sh; c notes/handoff.md; g push -q'
t other-branch allow 'g checkout -q -b other; c app.sh; g push -q -u origin other 2>/dev/null'
t second-stop allow 'c app.sh; g push -q' true
# Talk since the handoff.
t talk-3-messages allow 'user 3; tool'
t talk-4-messages block 'user 4'
t talk-before-handoff allow 'user 6 2000'
t talk-asked-once allow 'user 4; run block talk-asked-once/first'
t talk-asked-again-at-8 block 'user 4; run block talk-again/first; user 4'
# Messages from 2050, then a handoff commit dated 2060: only the messages after it count again.
late() { GIT_COMMITTER_DATE=2060-01-01T00:00:00Z c notes/handoff.md; g push -q; }
t talk-new-handoff-recount allow 'user 4 2050; run block talk-recount/first; late; user 3'
t talk-new-handoff-4-more block 'user 4 2050; run block talk-recount2/first; late; user 4'
t talk-unpushed allow 'user 4; c app.sh'
# Context size.
t ctx-below allow 'ctx 149000'
t ctx-150k block 'ctx 151000'
t ctx-150k-once allow 'ctx 151000; run block ctx-once/first; ctx 160000'
t ctx-200k-again block 'ctx 151000; run block ctx-again/first; ctx 201000'
t ctx-after-compaction block 'ctx 151000; run block ctx-compact/first; ctx 90000; run allow ctx-compact/compacted; ctx 152000'
t ctx-unpushed block 'c app.sh; ctx 151000'
t ctx-other-branch block 'g checkout -q -b other; ctx 151000'
t ctx-own-level allow 'echo CONTEXT_WARN=300000 >>$r/.claude/ground-truth.conf; ctx 250000'
t ctx-default-300k allow 'sed -i s/CONTEXT_WARN=150000// $r/.claude/ground-truth.conf; ctx 299000'
t ctx-default-300k-past block 'sed -i s/CONTEXT_WARN=150000// $r/.claude/ground-truth.conf; ctx 301000'
t path-with-space block 'tx="$tmp/a b.jsonl"; user 4'
t no-transcript-file allow 'tx=$tmp/missing.jsonl'
exit $fail
