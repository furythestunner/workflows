#!/bin/bash
# Tests for ground-truth.sh and .claude/hooks/session-start.sh: a scratch repo with a remote, and what the brief's
# facts must say about it. GitHub is a stand-in `gh` that answers the issues call with fixed lines.
# Usage: bash .claude/skills/session-start/ground-truth.test.sh   (exit 0 = all pass)
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
g() { git -C "$r" -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@"; }
has() { # <name> <text that must be in $out>
  case $out in *"$2"*) echo "ok    $1" ;; *) echo "FAIL  $1: no \"$2\" in the output"; fail=1 ;; esac
}
hasnot() { # <name> <text that must not be in $out>
  case $out in *"$2"*) echo "FAIL  $1: \"$2\" is in the output"; fail=1 ;; *) echo "ok    $1" ;; esac
}

# The stand-in gh: issues as "status<TAB>type<TAB>number<TAB>title" (what the script's --jq prints), no pull requests.
mkdir -p "$tmp/bin"
cat >"$tmp/bin/gh" <<'GH'
#!/bin/bash
case "$*" in
  *"/issues?"*) printf 'ready\tbug\t1\tApproved one\nin-progress\tfeature\t2\tBeing built\nbacklog\tdocs\t3\tLater\nblocked\tbug\t4\tOld status\ndone\tbug\t6\tGone status\n\tbug\t5\tNo status\n' ;;
esac
exit 0
GH
chmod +x "$tmp/bin/gh"

r="$tmp/r"
git init -q --bare "$tmp/o.git"; git init -q -b main "$r"; g remote add origin "$tmp/o.git"
mkdir -p "$r/.claude/skills/session-start" "$r/.claude/hooks" "$r/notes"
cp "$here/ground-truth.sh" "$r/.claude/skills/session-start/"
cp "$here/../../hooks/session-start.sh" "$r/.claude/hooks/"
printf '%s\n' 'REPOS=("demo|.|origin|main|o/demo")' 'ISSUES=1' 'UNITS=0' 'FACT_FILES="notes/lessons.md"' \
  'WORK_BRANCH="work"' 'HANDOFF="notes/handoff.md"' 'DOCS="notes"' >"$r/.claude/ground-truth.conf"
printf '%s\n' '- old fact (check by 2000-01-01)' '- fresh fact (check by 2999-01-01)' '- odd (check by next year)' \
  >"$r/notes/lessons.md"
printf '# Handoff\n\n## Next\n\n1. The marker task\n' >"$r/notes/handoff.md"
g add -A; g commit -qm first; g push -q -u origin main 2>/dev/null
g checkout -q -b work; g push -q -u origin work 2>/dev/null; g checkout -q main
gt() { (cd "$r" && PATH="$tmp/bin:$PATH" bash .claude/skills/session-start/ground-truth.sh "$@" 2>&1); }

# 1. Facts: a due one and a badly written tag are listed, a fresh one is not.
out=$(gt); code=$?
[ "$code" = 0 ] && echo "ok    exit 0 when every probe answers" || { echo "FAIL  exit $code, expected 0"; fail=1; }
has "due fact listed" "notes/lessons.md:1 (due 2000-01-01)"
has "bad tag listed" "BAD TAG (check by next year)"
hasnot "fresh fact not listed" "fresh fact"
has "ends complete" "GROUND TRUTH: complete"
# 2. The repo: pushed and clean.
has "clean checkout" ". [main]: = origin/main"
# 3. Issues: three statuses in order, an old or missing status asks for a label.
has "in progress first" "in-progress (1):"
has "ready listed" "#1 [bug] Approved one"
has "backlog listed, with the old Blocked one" "backlog (2):"
has "old Blocked shown as backlog" "#4 [bug] Old status (label is still Status: Blocked"
has "old Done needs a label" "#6 [bug] Gone status (status: done)"
has "no status needs a label" "#5 [bug] No status (status: none)"
hasnot "no merge mode line" "MERGE MODE"

# 4. Work that is only here: an unpushed commit and a loose file.
echo x >"$r/code.sh"; g add -A; g commit -qm code; echo y >"$r/loose.txt"
out=$(gt --no-fetch)
has "unpushed and uncommitted work" "ahead 1 / behind 0 of origin/main, 1 uncommitted"
rm "$r/loose.txt"

# 5. The session start hook, as a cloud session on another branch: it moves to the work branch and prints the
#    handoff; no skills list, no measured rounds. Code newer than the handoff is called out.
g push -q origin main 2>/dev/null; g checkout -q -b claude/x
ss() { (cd "$r" && PATH="$tmp/bin:$PATH" CLAUDE_PROJECT_DIR="$r" CLAUDE_CODE_REMOTE=true bash .claude/hooks/session-start.sh 2>&1); }
out=$(ss)
has "start: asks for the brief first" "Your FIRST reply in this session OPENS with the brief"
has "start: moved to the work branch" "Switched from 'claude/x' to work"
has "start: ground truth ran" "GROUND TRUTH: complete"
has "start: handoff printed" "The marker task"
has "start: handoff is current" "0 code commit(s) since"
hasnot "start: no cheat sheet" "CHEATSHEET.md"
hasnot "start: no rounds" "rounds.md"
echo z >"$r/more.sh"; g add -A; g commit -qm "more code"; g push -q origin work 2>/dev/null
out=$(ss)
has "start: stale handoff called out" "STALE HANDOFF"
# The off switch on the work branch: a session that starts on another branch still says so, and stops there.
: >"$r/.claude/workflow-off"; g add -A; g commit -qm off; g push -q origin work 2>/dev/null; g checkout -q claude/x
out=$(ss)
has "start: off switch seen after the move" "WORKFLOW OFF"
hasnot "start: off, no ground truth" "GROUND TRUTH"
exit $fail
