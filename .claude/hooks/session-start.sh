#!/bin/bash
# SessionStart hook: does what /session-start step 1 did by hand, so nobody has to remember it.
# Cloud sessions are moved to WORK_BRANCH (.claude/ground-truth.conf); on the PC the branch is left alone.
# Everything printed here is added to Claude's context before the first message.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
WORK_BRANCH="" HANDOFF="notes/handoff.md" DOCS="notes BACKLOG.md questions.md CLAUDE.md README.md"
[ -f .claude/ground-truth.conf ] && . .claude/ground-truth.conf
excl=(); for d in $DOCS; do excl+=(":(exclude)$d"); done

echo "AUTOMATIC SESSION START (hook .claude/hooks/session-start.sh). Step 1 of /session-start is done below."
echo "Your FIRST reply in this session OPENS with the brief: steps 2 to 5 of .claude/skills/session-start/SKILL.md,"
echo "using the ground truth and handoff below (do not run the script again). The brief comes first, at most about 8"
echo "short lines: anything wrong or due, \"Claude next\" (every Next item, one line), one 🟡 line per Waiting item (full"
echo "steps only for items added at the last update), one recommended task. Then a horizontal line (---), then the"
echo "answer to the first message."
echo

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] && [ -n "$WORK_BRANCH" ]; then
  git fetch -q origin "$WORK_BRANCH" main 2>/dev/null || echo "WARNING: git fetch failed; branch state may be old."
  current=$(git branch --show-current)
  if [ "$current" != "$WORK_BRANCH" ]; then
    if git diff --quiet && git diff --cached --quiet; then
      if git checkout -q "$WORK_BRANCH" 2>/dev/null || git checkout -q -b "$WORK_BRANCH" "origin/$WORK_BRANCH" 2>/dev/null; then
        echo "Switched from '$current' to $WORK_BRANCH (cloud sessions work on $WORK_BRANCH)."
      else
        echo "WARNING: $WORK_BRANCH exists neither here nor on origin; stayed on '$current'."
      fi
    else
      echo "WARNING: uncommitted changes on '$current'; NOT switched to $WORK_BRANCH. Sort this out first."
    fi
  fi
  if [ "$(git branch --show-current)" = "$WORK_BRANCH" ]; then
    git pull -q --ff-only origin "$WORK_BRANCH" 2>/dev/null || echo "WARNING: $WORK_BRANCH could not fast-forward to origin; check before working."
  fi
else
  # PC: fetch (one retry: it can fail once on a cold start), then fast-forward the checked-out branch only when that
  # is safe: nothing uncommitted and no commits that exist only here. Otherwise leave it alone and say why.
  if git fetch -q origin 2>/dev/null || { sleep 3; git fetch -q origin 2>/dev/null; }; then
    current=$(git branch --show-current)
    if [ -n "$current" ] && git rev-parse -q --verify '@{u}' >/dev/null 2>&1; then
      behind=$(git rev-list --count 'HEAD..@{u}') ahead=$(git rev-list --count '@{u}..HEAD')
      if [ "$behind" -gt 0 ]; then
        if ! git diff --quiet || ! git diff --cached --quiet; then
          echo "WARNING: '$current' is $behind commit(s) behind origin but has uncommitted changes; NOT updated. Brief may be old."
        elif [ "$ahead" -gt 0 ]; then
          echo "WARNING: '$current' is $behind behind and $ahead ahead of origin; NOT updated. Sort this out first."
        elif git merge -q --ff-only '@{u}' 2>/dev/null; then
          echo "Updated '$current' from origin: $behind commit(s) pulled (nothing local was waiting)."
        else
          echo "WARNING: '$current' could not fast-forward to origin (a loose file in the way?); NOT updated."
        fi
      fi
    fi
  else
    echo "WARNING: git fetch failed twice; branch state may be old and the copy was NOT updated."
  fi
fi

echo "Branch: $(git branch --show-current)"
# The off switch (.claude/hooks/run.mjs) is usually created on the work branch: a cloud session sees it only now.
if [ -e .claude/workflow-off ]; then
  echo
  echo "WORKFLOW OFF: the file .claude/workflow-off exists, so no workflow hook runs in this repo from here on (no"
  echo "guards, no handoff check). Say this first in your reply, instead of the brief. To turn the hooks back on, the"
  echo "user deletes that file on GitHub and starts a new session."
  exit 0
fi
echo
timeout 60 bash .claude/skills/session-start/ground-truth.sh 2>&1 | head -150
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
# This project's own skills (not synced from the master copy), for Claude; not listed in the brief. The shared
# skills are not printed: Claude Code lists every skill with its description by itself.
if [ -f .claude/skills/CHEATSHEET.project.md ]; then
  echo
  echo "===== .claude/skills/CHEATSHEET.project.md (this repo's own skills; for Claude, not listed in the brief) ====="
  sed -n '/^## Skills/,$p' .claude/skills/CHEATSHEET.project.md | head -20
fi
exit 0
