#!/bin/bash
# The checks CI runs on every pull request (.github/workflows/check.yml). Run them locally the same way:
#   bash scripts/check.sh        (exit 0 = all pass)
cd "$(dirname "$0")/.." || exit 1
fail=0
err=$(mktemp); trap 'rm -f "$err"' EXIT
ok()  { echo "ok    $*"; }
bad() { echo "FAIL  $*"; fail=1; }

# 1. Every shell script parses.
while IFS= read -r f; do
  if bash -n "$f" 2>"$err"; then ok "bash -n $f"; else bad "bash -n $f: $(cat "$err")"; fi
done < <(git ls-files '*.sh')

# 2. Every node hook parses.
while IFS= read -r f; do
  if node --check "$f" 2>"$err"; then ok "node --check $f"; else bad "node --check $f: $(head -3 "$err")"; fi
done < <(git ls-files '*.mjs' '*.js')

# 3. settings.json is valid JSON and every hook file it runs exists.
if node -e '
  const s = JSON.parse(require("fs").readFileSync(".claude/settings.json", "utf8"));
  const missing = [];
  for (const groups of Object.values(s.hooks || {}))
    for (const g of groups)
      for (const h of g.hooks || []) {
        const m = (h.command || "").match(/\$CLAUDE_PROJECT_DIR\/([^"\s]+)/);
        if (m && !require("fs").existsSync(m[1])) missing.push(m[1]);
      }
  if (missing.length) { console.error("missing: " + missing.join(", ")); process.exit(1); }
' 2>"$err"; then ok ".claude/settings.json: valid, hook files exist"; else bad ".claude/settings.json: $(cat "$err")"; fi

# 4. The guards block and allow what their tests say.
for f in .claude/hooks/*.test.sh; do
  if out=$(bash "$f" 2>&1); then ok "$(basename "$f")"
  else bad "$(basename "$f")"; echo "$out" | grep FAIL; fi
done

# 5. The cheat sheet names every skill (the brief's "Your skills" list comes from it).
for d in .claude/skills/*/; do
  n=$(basename "$d")
  if grep -q "\`/$n\`" .claude/skills/CHEATSHEET.md; then ok "CHEATSHEET.md lists /$n"
  else bad "CHEATSHEET.md does not list /$n"; fi
done
n=$(sed -n '/^## Skills/,$p' .claude/skills/CHEATSHEET.md | wc -l)
if [ "$n" -le 60 ]; then ok "CHEATSHEET.md fits what session-start.sh prints ($n of 60 lines)"
else bad "CHEATSHEET.md: $n lines from \"## Skills\"; session-start.sh prints only 60"; fi

# 6. The shared rules file is there and holds no project values (every repo gets it as it is).
if [ ! -f .claude/rules/workflow.md ]; then bad ".claude/rules/workflow.md is missing"
elif grep -nE '<user>|<work branch>|Balázs|dev-test' .claude/rules/workflow.md >"$err"; then
  bad ".claude/rules/workflow.md has project values: $(head -3 "$err")"
else ok ".claude/rules/workflow.md: shared, no project values"; fi

# 7. The sync works on an empty repo: files copied, settings.json merged with its hooks, manifest written.
tmp=$(mktemp -d)
if git init -q "$tmp" && bash scripts/sync.sh "$tmp" >"$err" 2>&1 &&
   [ -f "$tmp/.claude/rules/workflow.md" ] && [ -s "$tmp/.claude/workflow-manifest" ] &&
   node -e 'const s=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); if(!s.hooks||!s.hooks.SessionStart) process.exit(1)' "$tmp/.claude/settings.json"
then ok "scripts/sync.sh into an empty repo"
else bad "scripts/sync.sh into an empty repo: $(head -3 "$err")"; fi
rm -rf "$tmp"

# 8. Files loaded into every session, or read whole by a skill, stay short. A warning, not a failure: /distill
#    shortens one without losing a rule.
long() { # <file> <max lines>
  local n; n=$(wc -l <"$1")
  if [ "$n" -gt "$2" ]; then echo "WARN  $1: $n lines, over $2; shorten it with /distill"; else ok "$1: $n lines"; fi
}
long .claude/rules/workflow.md 80
long CLAUDE.md 60
for f in .claude/skills/*/SKILL.md; do long "$f" 120; done

exit $fail
