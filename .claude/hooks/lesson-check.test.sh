#!/bin/bash
# Tests for lesson-check.mjs: each case is a project (notes/lessons.md, the shared file, project or master copy),
# a turn with Claude's edits to notes/lessons.md, and whether the hook must send Claude back.
# Usage: bash .claude/hooks/lesson-check.test.sh   (exit 0 = all pass)
cd "$(dirname "$0")" || exit 1
hook=$(pwd)/lesson-check.mjs
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
SHARED_LESSON='- Shared one: holds in every repo.'
t() { # <block|allow> <name> <lessons.md text> <edit new_string or ""> [master] [stop_hook_active]
  local p="$tmp/p" f="$tmp/t.jsonl" out got
  rm -rf "$p"; mkdir -p "$p/notes" "$p/.claude/rules"
  printf '%s\n' "$3" >"$p/notes/lessons.md"
  printf '# Shared lessons\n\n%s\n' "$SHARED_LESSON" >"$p/.claude/rules/shared-lessons.md"
  [ "${5:-}" = master ] || echo "workflows abc1234" >"$p/.claude/workflow-version"
  node -e '
    const [file, add] = process.argv.slice(1);
    const lines = [{ type: "user", message: { content: "do it" } }];
    if (add) lines.push({ type: "assistant", message: { content: [{ type: "tool_use", name: "Edit",
      input: { file_path: file, old_string: "## Hook candidates", new_string: add } }] } });
    lines.push({ type: "assistant", message: { content: [{ type: "text", text: "Done." }] } });
    process.stdout.write(lines.map(l => JSON.stringify(l)).join("\n") + "\n");
  ' "$p/notes/lessons.md" "$4" >"$f"
  # Git Bash on Windows: a path inside the JSON is not converted for node, so pass the Windows form
  local fj; fj=$(cygpath -m "$f" 2>/dev/null || echo "$f")
  out=$(printf '{"transcript_path":"%s","stop_hook_active":%s}' "$fj" "${6:-false}" |
    CLAUDE_PROJECT_DIR="$p" node "$hook")
  case $out in *'"block"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: $2"; else echo "FAIL  expected $1, got $got: $2 ($out)"; fail=1; fi
}
PROJ=$'# Lessons\n\n## Building tools\n\n- Old project lesson.\n- New lesson about the tab,\n  second line.\n\n## Hook candidates\n'
SHAREDSEC=$'# Lessons\n\n## Hook candidates\n\n## Shared (goes to every repo)\n\n- New lesson about the tab,\n  second line.\n'
ARRIVED=$'# Lessons\n\n## Shared (goes to every repo)\n\n- Shared one: holds in every repo.\n'
ADD=$'- New lesson about the tab,\n  second line.'
t block 'lesson added in a project section' "$PROJ" "$ADD"
t allow 'lesson added under Shared' "$SHAREDSEC" "$ADD"
t allow 'no edit to notes/lessons.md' "$PROJ" ''
t allow 'edit that adds no bullet' "$PROJ" '## Hook candidates (none)'
t block 'shared lesson already arrived with the sync' "$ARRIVED" ''
t block 'master copy: lesson added to notes/lessons.md' "$PROJ" "$ADD" master
t allow 'master copy: arrived check does not apply' "$ARRIVED" '' master
t allow 'second stop (stop_hook_active)' "$PROJ" "$ADD" '' true
out=$(printf '{bad' | node "$hook" 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
