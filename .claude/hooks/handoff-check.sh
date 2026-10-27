#!/bin/bash
# Stop hook: keeps the handoff current without anyone typing /handoff.
# After each reply: if code commits on WORK_BRANCH are pushed but the handoff is older than them, Claude is sent
# back once to update the handoff and push it. Unpushed work is left alone (work in progress).
# Commits touching only DOCS (.claude/ground-truth.conf) do not count as work.
input=$(cat)
case "$input" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
WORK_BRANCH="" HANDOFF="notes/handoff.md" DOCS="notes BACKLOG.md questions.md CLAUDE.md README.md" USER_NAME="the user"
[ -f .claude/ground-truth.conf ] && . .claude/ground-truth.conf
[ -n "$WORK_BRANCH" ] || exit 0
excl=(); for d in $DOCS; do excl+=(":(exclude)$d"); done
[ "$(git branch --show-current 2>/dev/null)" = "$WORK_BRANCH" ] || exit 0
git rev-parse -q --verify '@{u}' >/dev/null 2>&1 || exit 0
[ "$(git rev-list --count '@{u}..HEAD')" = "0" ] || exit 0
h=$(git log -1 --format=%H -- "$HANDOFF")
[ -n "$h" ] || exit 0
n=$(git rev-list --count --no-merges "$h"..HEAD -- . "${excl[@]}")
[ "$n" -gt 0 ] || exit 0
cat <<JSON
{"decision":"block","reason":"Handoff is behind: $n pushed code commit(s) on $WORK_BRANCH are newer than $HANDOFF. Before stopping, bring its three sections up to date (.claude/rules/workflow.md, Sessions and trackers): Next, Waiting for $USER_NAME, Unfinished; drop items that landed (their issues close when the pull request merges). If nothing in them changed, update only the date line. Then stage only those files (and notes/rounds.md if it changed), commit and push to $WORK_BRANCH (handoff rule: no need to ask). One line to the user that the handoff was updated."}
JSON
exit 0
