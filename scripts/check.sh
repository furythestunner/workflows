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

# 4. The issue guard blocks and allows what its tests say.
if out=$(bash .claude/hooks/issue-guard.test.sh 2>&1); then ok "issue-guard.test.sh"
else bad "issue-guard.test.sh"; echo "$out" | grep FAIL; fi

# 5. The cheat sheet names every skill (the brief's "Your skills" list comes from it).
for d in .claude/skills/*/; do
  n=$(basename "$d")
  if grep -q "\`/$n\`" .claude/skills/CHEATSHEET.md; then ok "CHEATSHEET.md lists /$n"
  else bad "CHEATSHEET.md does not list /$n"; fi
done

# 6. This repo's CLAUDE.md carries README.md's rules block, with dev-test and Balázs filled in.
want=$(awk '/^## CLAUDE.md block/{f=1;next} f&&/^```markdown/{g=1;next} g&&/^```/{exit} g' README.md |
  sed 's/<work branch>/dev-test/g; s/<user>/Balázs/g')
have=$(sed -n '/^<!-- The block below is README.md/,/^<!-- End of the README.md block/p' CLAUDE.md | sed '1d;$d')
if [ -n "$want" ] && [ "$want" = "$have" ]; then ok "CLAUDE.md block matches README.md"
else bad "CLAUDE.md block differs from README.md's CLAUDE.md block"; fi

exit $fail
