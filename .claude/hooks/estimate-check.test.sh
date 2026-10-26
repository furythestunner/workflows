#!/bin/bash
# Tests for estimate-check.mjs: each case is a turn (the user's message, then Claude's reply and tool calls) and
# whether the hook must send Claude back.
# Usage: bash .claude/hooks/estimate-check.test.sh   (exit 0 = all pass)
cd "$(dirname "$0")" || exit 1
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
t() { # <block|allow> <reply text> [tool_use input JSON] [stop_hook_active]
  local f="$tmp/t.jsonl" out got
  node -e '
    const [reply, tool] = process.argv.slice(1);
    const lines = [{ type: "user", message: { content: "build it" } }];
    if (tool) lines.push({ type: "assistant", message: { content: [{ type: "tool_use", name: "Read", input: JSON.parse(tool) }] } });
    lines.push({ type: "assistant", message: { content: [{ type: "text", text: reply }] } });
    process.stdout.write(lines.map(l => JSON.stringify(l)).join("\n") + "\n");
  ' "$2" "$3" >"$f"
  out=$(printf '{"transcript_path":"%s","stop_hook_active":%s}' "$f" "${4:-false}" | node estimate-check.mjs)
  case $out in *'"block"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: $2"; else echo "FAIL  expected $1, got $got: $2"; fail=1; fi
}
t block 'It should take about 60 to 90 min.'
t block 'Roughly 2 hours of work.'
t block 'Körülbelül 30 perc.'
t block 'about 10-15 min'
t allow 'It should take about 60 to 90 min.' '{"file_path":"/x/notes/lessons.md"}'
t allow 'It should take about 60 to 90 min.' '' true
t allow 'Done. The pull request is open.'
t allow 'Version 2 of the hook, 3 repos synced.'
out=$(printf '{bad' | node estimate-check.mjs 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
