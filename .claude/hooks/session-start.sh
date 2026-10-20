#!/bin/bash
# SessionStart hook: does what /session-start step 1 did by hand, so nobody has to remember it.
# Cloud sessions are moved to WORK_BRANCH (.claude/ground-truth.conf); on the PC the branch is left alone.
# Everything printed here is added to Claude's context before the first message.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
WORK_BRANCH="" HANDOFF="notes/handoff.md" DOCS="notes BACKLOG.md questions.md CLAUDE.md README.md"
[ -f .claude/ground-truth.conf ] && . .claude/ground-truth.conf
excl=(); for d in $DOCS; do excl+=(":(exclude)$d"); done

echo "AUTOMATIC SESSION START (hook .claude/hooks/session-start.sh). Step 1 of /session-start is done below."
echo "Your FIRST reply in this session, whatever the user writes, begins with the brief: follow steps 2 to 5 of"
echo ".claude/skills/session-start/SKILL.md, using the ground truth and handoff below (do not run the script again)."
echo "If the first message is a specific task, keep the brief to 3 lines (contradictions, anything due) and then do the task."
echo

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] && [ -n "$WORK_BRANCH" ]; then
  git fetch -q origin "$WORK_BRANCH" main 2>/dev/null || echo "WARNING: git fetch failed; branch state may be old."
  current=$(git branch --show-current)
  if [ "$current" != "$WORK_BRANCH" ]; then
    if git diff --quiet && git diff --cached --quiet; then
      git checkout -q "$WORK_BRANCH" 2>/dev/null || git checkout -q -b "$WORK_BRANCH" "origin/$WORK_BRANCH"
      echo "Switched from '$current' to $WORK_BRANCH (cloud sessions work on $WORK_BRANCH)."
    else
      echo "WARNING: uncommitted changes on '$current'; NOT switched to $WORK_BRANCH. Sort this out first."
    fi
  fi
  if [ "$(git branch --show-current)" = "$WORK_BRANCH" ]; then
    git pull -q --ff-only origin "$WORK_BRANCH" 2>/dev/null || echo "WARNING: $WORK_BRANCH could not fast-forward to origin; check before working."
  fi
else
  git fetch -q origin 2>/dev/null || echo "WARNING: git fetch failed; branch state may be old."
fi

echo "Branch: $(git branch --show-current)"
echo
timeout 60 bash .claude/skills/session-start/ground-truth.sh 2>&1 | head -80
echo

# Handoff freshness: code commits after the last handoff commit (DOCS excluded).
h=$(git log -1 --format=%H -- "$HANDOFF")
if [ -n "$h" ]; then
  n=$(git rev-list --count --no-merges "$h"..HEAD -- . "${excl[@]}")
  echo "HANDOFF: last written $(git log -1 --format='%ad' --date=format:'%Y-%m-%d %H:%M' "$h"); $n code commit(s) since."
  if [ "$n" -gt 0 ]; then
    echo "STALE HANDOFF: say so first in the brief. Work since then:"
    git log --no-merges --format='  %ad %s' --date=short "$h"..HEAD -- . "${excl[@]}" | head -25
  fi
fi
echo
echo "===== $HANDOFF ====="
head -80 "$HANDOFF" 2>/dev/null || echo "(missing)"
exit 0
