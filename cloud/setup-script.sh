#!/bin/bash
# Cloud environment setup script: paste this whole file into the environment's "Setup script" box
# (claude.ai/code: environment menu in the session's title bar, Edit, Setup script).
#
# Why: a cloud session with two or more repos opens in the folder that holds them, not inside a repo, so no repo's
# own SessionStart hook runs (no brief, no skills list, no branch switch). This installs a user-level hook that finds
# the repos in that folder and runs each one's .claude/hooks/session-start.sh. In a one-repo session it does nothing:
# that repo's own hook runs as usual. Safe to run more than once. Issue: furythestunner/workflows#10.

mkdir -p "$HOME/.claude/hooks"

cat > "$HOME/.claude/hooks/multi-repo-start.sh" <<'HOOK'
#!/bin/bash
# User-level SessionStart hook, installed by cloud/setup-script.sh of furythestunner/workflows.
root="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -f "$root/.claude/hooks/session-start.sh" ] && exit 0   # the session opened inside a repo: its own hook runs
repos=()
for d in "$root"/*/; do [ -f "$d.claude/hooks/session-start.sh" ] && repos+=("${d%/}"); done
[ ${#repos[@]} -eq 0 ] && exit 0

names=(); for r in "${repos[@]}"; do names+=("$(basename "$r")"); done
echo "MULTI-REPO SESSION START (user hook ~/.claude/hooks/multi-repo-start.sh): ${#repos[@]} repos, ${names[*]}."
echo "The session opened in $root, outside the repos, so each repo's own start-up ran from here; its output follows."
echo "Your FIRST reply begins with the brief: one short section per repo (steps 2 to 5 of its session-start skill,"
echo "a few lines each: contradictions, anything due, the proposed task), then \"Your skills\" ONCE at the end,"
echo "each skill listed once even when several repos have it. If the first message is a specific task, keep it to"
echo "3 lines per repo and then do the task. Per-repo rules (branches, trackers) come from each repo's CLAUDE.md."
last="${repos[${#repos[@]}-1]}"
for r in "${repos[@]}"; do
  echo
  echo "################ REPO $(basename "$r") ($r) ################"
  # The skills cheat sheet is printed only by the last repo, so the list comes once.
  if [ "$r" = "$last" ]; then cut=''; else cut='/^===== .claude\/skills\/CHEATSHEET.md/,$d'; fi
  (cd "$r" && CLAUDE_PROJECT_DIR="$r" timeout 120 bash .claude/hooks/session-start.sh 2>&1) | sed "$cut"
done
exit 0
HOOK
chmod +x "$HOME/.claude/hooks/multi-repo-start.sh"

# Add the hook to ~/.claude/settings.json, keeping anything already there and adding it only once.
node -e '
const fs = require("fs"), f = process.env.HOME + "/.claude/settings.json";
let s = {}; try { s = JSON.parse(fs.readFileSync(f, "utf8")); } catch {}
const cmd = "bash \"$HOME/.claude/hooks/multi-repo-start.sh\"";
s.hooks ??= {}; s.hooks.SessionStart ??= [];
if (!JSON.stringify(s.hooks.SessionStart).includes("multi-repo-start.sh"))
  s.hooks.SessionStart.push({ matcher: "startup|clear|compact", hooks: [{ type: "command", command: cmd, timeout: 300 }] });
fs.writeFileSync(f, JSON.stringify(s, null, 2) + "\n");
'
echo "multi-repo session start installed"
