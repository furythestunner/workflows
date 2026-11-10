#!/bin/bash
# Tests for fact-check.mjs: each case is Claude's reply this turn and the tools it used, and whether the hook must
# send Claude back.
# Usage: bash .claude/hooks/fact-check.test.sh   (exit 0 = all pass)
hook=$(cd "$(dirname "$0")" && pwd)/fact-check.mjs
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
command -v cygpath >/dev/null && tmp=$(cygpath -m "$tmp") # node on Windows needs C:/...
fail=0
t() { # <block|none> <name> <reply> [tool name] [bash command] [stop_hook_active: true]
  local out got
  node -e '
    const [reply, tool, cmd] = process.argv.slice(1);
    const lines = [{ type: "user", message: { content: "earlier" } },
      { type: "assistant", message: { content: [{ type: "tool_use", name: "Read", input: {} }] } },
      { type: "user", message: { content: "what do we have?" } }];
    if (tool) lines.push({ type: "assistant", message: { content: [{ type: "tool_use", name: tool, input: { command: cmd } }] } });
    lines.push({ type: "assistant", message: { content: [{ type: "text", text: reply }] } });
    process.stdout.write(lines.map(l => JSON.stringify(l)).join("\n") + "\n");
  ' "$3" "${4:-}" "${5:-}" >"$tmp/t.jsonl"
  out=$(printf '{"transcript_path":"%s","stop_hook_active":%s}' "$tmp/t.jsonl" "${6:-false}" | node "$hook")
  [ -n "$out" ] && got=block || got=none
  if [ "$got" = "$1" ]; then echo "ok    $1: $2"; else echo "FAIL  expected $1, got $got: $2"; fail=1; fi
}
t block 'claim, no file opened' 'The setup already has a fact rule.'
t block 'negative claim, no file opened' 'There is no hook for that yet.'
t none 'claim, Read this turn' 'The setup already has a fact rule.' Read
t none 'claim, grep in Bash this turn' 'There is no hook for that.' Bash 'grep -rn fact .claude'
t block 'claim, Bash that reads nothing' 'There is no hook for that.' Bash 'git push -u origin dev-test'
t none 'no claim' 'Done: the pull request is open.'
t none 'claim only inside code' 'Run `there is no` in the shell.'
t none 'second stop (already sent back)' 'There is no hook for that.' '' '' true
out=$(printf '{bad' | node "$hook" 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
