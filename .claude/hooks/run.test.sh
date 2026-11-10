#!/bin/bash
# Tests for run.mjs (the runner every hook goes through): a hook's answer passes through, the off switch stops
# every hook, Claude cannot create the off switch, and fires and skills are counted into notes/usage.md.
# Usage: bash .claude/hooks/run.test.sh   (exit 0 = all pass)
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
command -v cygpath >/dev/null && tmp=$(cygpath -m "$tmp") # node on Windows needs C:/...
fail=0
r="$tmp/r"; git init -q "$r"; mkdir -p "$r/.claude" "$r/notes"
echo 'HANDOFF="notes/handoff.md"' >"$r/.claude/ground-truth.conf"
run() { CLAUDE_PROJECT_DIR="$r" node "$here/run.mjs" "$@"; }
t() { # <name> <block|allow> <hook or mode> <stdin JSON>
  local out got
  out=$(printf '%s' "$4" | run "$3")
  case $out in *'"deny"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$2" ]; then echo "ok    $2: $1"; else echo "FAIL  expected $2, got $got: $1"; fail=1; fi
}
is() { # <name> <got> <expected>
  if [ "$2" = "$3" ]; then echo "ok    $1"; else echo "FAIL  $1: got \"$2\", expected \"$3\""; fail=1; fi
}
close='{"tool_name":"Bash","tool_input":{"command":"gh issue close 3"}}'
off=.claude/workflow-off

# A hook's answer passes through, and a call it lets through stays silent.
t "the issue guard still blocks through the runner" block issue-guard.mjs "$close"
t "a harmless call passes" allow issue-guard.mjs '{"tool_name":"Bash","tool_input":{"command":"git status"}}'
t "an unknown hook name does nothing" allow no-such-hook.mjs "$close"

# Claude may not create the off switch; text that only names it passes.
t "Write to the off switch" block synced-guard.mjs "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$r/$off\",\"content\":\"\"}}"
t "touch the off switch" block issue-guard.mjs "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"touch $off\"}}"
t "redirect into the off switch" block issue-guard.mjs "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"cd x && date > $off\"}}"
t "a commit message that names it" allow issue-guard.mjs "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git commit -m 'Docs: $off turns the hooks off'\"}}"
t "reading it" allow issue-guard.mjs "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls -la $off\"}}"
t "Write to another file" allow synced-guard.mjs "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$r/notes/x.md\",\"content\":\"$off\"}}"

# Skills are counted: typed, or through the Skill tool.
printf '%s' '{"prompt":"/handoff now"}' | run dash-check.mjs >/dev/null
printf '%s' '{"tool_name":"Skill","tool_input":{"skill":"plain"}}' | run --skill >/dev/null
printf '%s' '{"prompt":"what is /handoff?"}' | run dash-check.mjs >/dev/null

# The counts so far: one line per fire (the 4 blocks above came from 1 hook and 3 times the runner itself).
log=$(git -C "$r" rev-parse --git-path workflow-usage.log); case $log in /*|?:*) ;; *) log="$r/$log" ;; esac
is "log: the guard's block" "$(grep -c 'issue-guard$' "$log")" 1
is "log: typed skill" "$(grep -c 'skill handoff$' "$log")" 1
is "log: Skill tool" "$(grep -c 'skill plain$' "$log")" 1

# --fold: the log goes into notes/usage.md and is emptied; a second fold adds up.
run --fold
is "fold: usage.md has the guard" "$(grep -c '^| `issue-guard` | 1 | ' "$r/notes/usage.md")" 1
is "fold: usage.md has the skill" "$(grep -c '^| `skill plain` | 1 | ' "$r/notes/usage.md")" 1
is "fold: the log is empty" "$(wc -c <"$log" | tr -d ' ')" 0
printf '%s' "$close" | run issue-guard.mjs >/dev/null; run --fold
is "fold: counts add up" "$(grep -c '^| `issue-guard` | 2 | ' "$r/notes/usage.md")" 1
before=$(cat "$r/notes/usage.md"); run --fold
is "fold: nothing new, nothing changes" "$(cat "$r/notes/usage.md")" "$before"

# The off switch: no hook runs, and the session start says so.
: >"$r/$off"
t "off: the guard does not run" allow issue-guard.mjs "$close"
out=$(printf '{}' | run session-start.sh)
case $out in "WORKFLOW OFF"*) echo "ok    off: the session start says WORKFLOW OFF" ;; *) echo "FAIL  off: session start printed: ${out:0:80}"; fail=1 ;; esac
is "off: nothing counted" "$(wc -c <"$log" | tr -d ' ')" 0
rm "$r/$off"
t "on again: the guard runs" block issue-guard.mjs "$close"
exit $fail
