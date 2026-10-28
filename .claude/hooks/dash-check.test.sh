#!/bin/bash
# Tests for dash-check.mjs: each case is a CLAUDE.md, Claude's previous reply and the new message, and whether the
# hook must remind Claude.
# Usage: bash .claude/hooks/dash-check.test.sh   (exit 0 = all pass)
hook=$(cd "$(dirname "$0")" && pwd)/dash-check.mjs
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
command -v cygpath >/dev/null && tmp=$(cygpath -m "$tmp") # node on Windows needs C:/...
fail=0
dash=$(printf '\xe2\x80\x94')
t() { # <remind|none> <name> <CLAUDE.md text> <previous reply> [new message already in the transcript: yes]
  local out got
  echo "$3" >"$tmp/CLAUDE.md"
  node -e '
    const [reply, written] = process.argv.slice(1);
    const lines = [{ type: "user", message: { content: written === "same" ? "next" : "first" } },
      { type: "assistant", message: { content: [{ type: "text", text: reply }] } }];
    if (written === "yes") lines.push({ type: "user", message: { content: "next" } });
    process.stdout.write(lines.map(l => JSON.stringify(l)).join("\n") + "\n");
  ' "$4" "${5:-}" >"$tmp/t.jsonl"
  out=$(printf '{"prompt":"next","transcript_path":"%s"}' "$tmp/t.jsonl" | CLAUDE_PROJECT_DIR=$tmp node "$hook")
  [ -n "$out" ] && got=remind || got=none
  if [ "$got" = "$1" ]; then echo "ok    $1: $2"; else echo "FAIL  expected $1, got $got: $2"; fail=1; fi
}
t remind 'dash, rule' 'No em dashes.' "Done $dash the PR is open."
t remind 'dash, rule, message written' 'No em dashes.' "Done $dash the PR is open." yes
t remind 'same text twice, new one not written yet' 'No em dashes.' "Done $dash the PR is open." same
t none 'no dash' 'No em dashes.' 'Done: the PR is open.'
t none 'dash, no rule' 'Plain words.' "Done $dash the PR is open."
t none 'hyphen only' 'No em dashes.' 'A two-way door - fine.'
out=$(printf '{bad' | node "$hook" 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
