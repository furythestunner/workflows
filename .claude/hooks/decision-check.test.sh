#!/bin/bash
# Tests for decision-check.mjs: each case is a turn (the user's message, Claude's tool calls) and whether the hook
# must send Claude back to record a decision.
# Usage: bash .claude/hooks/decision-check.test.sh   (exit 0 = all pass)
cd "$(dirname "$0")" || exit 1
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
command -v cygpath >/dev/null && tmp=$(cygpath -m "$tmp") # node on Windows needs C:/...
fail=0
t() { # <block|allow> <user message> [tool name] [tool input JSON] [stop_hook_active]
  local f="$tmp/t.jsonl" out got
  node -e '
    const [msg, name, inp] = process.argv.slice(1);
    const lines = [{ type: "user", message: { content: msg } }];
    if (name) lines.push({ type: "assistant", message: { content: [{ type: "tool_use", name, input: JSON.parse(inp || "{}") }] } });
    lines.push({ type: "assistant", message: { content: [{ type: "text", text: "Done." }] } });
    process.stdout.write(lines.map(l => JSON.stringify(l)).join("\n") + "\n");
  ' "$2" "$3" "$4" >"$f"
  out=$(printf '{"transcript_path":"%s","stop_hook_active":%s}' "$f" "${5:-false}" | node decision-check.mjs)
  case $out in *'"block"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: $2 ${3:-}"; else echo "FAIL  expected $1, got $got: $2 ${3:-}"; fail=1; fi
}
t block 'From now on the brief is in Hungarian.'
t block 'I decided: no plugins.'
t block 'Mostantól minden PR-t én mergelek.'
t block 'pick one' AskUserQuestion '{"questions":[]}'
t allow 'What was the decision on #12?'
t allow 'Mi a szabály erre?'
t allow 'Fix the typo in the README.'
t allow 'From now on the brief is in Hungarian.' Edit '{"file_path":"/x/questions.md"}'
t allow 'From now on the brief is in Hungarian.' Edit '{"file_path":"/x/README.md"}'
mkdir -p "$tmp/p/.claude"; echo v >"$tmp/p/.claude/workflow-version"
CLAUDE_PROJECT_DIR=$tmp/p t block 'From now on exports go to O:.' Edit '{"file_path":"/x/README.md"}'
t allow 'From now on the brief is in Hungarian.' Write '{"file_path":"/x/.claude/rules/workflow.md"}'
t block 'From now on the brief is in Hungarian.' Bash '{"command":"cat questions.md"}'
t allow 'From now on the brief is in Hungarian.' Bash '{"command":"echo x >> questions.md"}'
t allow 'From now on the brief is in Hungarian.' mcp__github__issue_write '{"method":"create"}'
t allow 'From now on the brief is in Hungarian.' Bash '{"command":"gh issue create -t x"}'
t allow 'From now on the brief is in Hungarian.' '' '' true
out=$(printf '{bad' | node decision-check.mjs 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
