#!/bin/bash
# Tests for synced-guard.mjs: a scratch project repo with a manifest; each case is a file edit and whether the guard
# must block it.
# Usage: bash .claude/hooks/synced-guard.test.sh   (exit 0 = all pass)
hook=$(cd "$(dirname "$0")" && pwd)/synced-guard.mjs
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
command -v cygpath >/dev/null && tmp=$(cygpath -m "$tmp") # node on Windows needs C:/...
fail=0
p="$tmp/project"; m="$tmp/master"
git init -q -b work "$p"; mkdir -p "$p/.claude/hooks" "$m/.claude"
printf '# Files synced\n.claude/hooks/x.mjs\n.claude/rules/workflow.md\n' >"$p/.claude/workflow-manifest"
echo 'workflows abc1234' >"$p/.claude/workflow-version"
cp "$p/.claude/workflow-manifest" "$m/.claude/"  # a master copy has no workflow-version
t() { # <block|allow> <tool> <file> [project dir]
  local out got
  out=$(printf '{"tool_name":"%s","tool_input":{"file_path":"%s"}}' "$2" "$3" | CLAUDE_PROJECT_DIR=${4:-$p} node "$hook")
  case $out in *'"deny"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: $2 $3"; else echo "FAIL  expected $1, got $got: $2 $3"; fail=1; fi
}
t block Edit "$p/.claude/hooks/x.mjs"
t block Write "$p/.claude/rules/workflow.md"
t block Edit .claude/hooks/x.mjs
t allow Edit "$p/CLAUDE.md"
t allow Edit "$p/.claude/ground-truth.conf"
t allow Write "$p/.claude/skills/own/SKILL.md"
t allow Edit "$m/.claude/hooks/x.mjs" "$m"
git -C "$p" checkout -q -b workflow-sync
t allow Edit "$p/.claude/hooks/x.mjs"
out=$(printf '{bad' | node "$hook" 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
