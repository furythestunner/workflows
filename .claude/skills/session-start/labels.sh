#!/usr/bin/env bash
#
# labels.sh — creates the "Type: x" and "Status: x" issue labels in every GitHub repo of .claude/ground-truth.conf.
# Safe to run again: a label that exists is updated to the colour and description below. A label under its old name
# ("status::ready", until 22 Oct 2026) is renamed, so every issue keeps its status. The statuses dropped on
# 10 Nov 2026 (Blocked, Review) are moved to the ones that stay and deleted. Other labels are left alone.
# The issue guard (.claude/hooks/issue-guard.mjs) lets this script through: creating a label applies it to nothing.
#
# Usage: bash .claude/skills/session-start/labels.sh

set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
REPOS=()
# shellcheck source=/dev/null
[ -f "$ROOT/.claude/ground-truth.conf" ] && . "$ROOT/.claude/ground-truth.conf"

LABELS=(
  "type::feature|Type: Feature|1d76db|Something new"
  "type::bug|Type: Bug|d73a4a|Something that does not work"
  "type::config|Type: Config|5319e7|A setting or a server, no code"
  "type::docs|Type: Docs|0075ca|Writing only"
  "status::backlog|Status: Backlog|ededed|Not approved yet, has a question for the owner, or on hold"
  "status::ready|Status: Ready|0e8a16|Approved: only the owner sets this"
  "status::in-progress|Status: In progress|fbca04|Claude is working on it, until its pull request is merged"
)
# Statuses dropped on 10 Nov 2026 (three are enough for one person): open issues move to the status on the right,
# then the label is deleted. "Status: Done" issues are left for the owner to close.
RETIRED=(
  "Status: Blocked|Status: Backlog"
  "Status: Review|Status: In progress"
  "Status: Done|"
)
uri() { jq -rn --arg s "$1" '$s|@uri'; }

failed=0
for spec in "${REPOS[@]}"; do
  IFS='|' read -r name _ _ _ gh_repo <<<"$spec"
  if [ -z "$gh_repo" ]; then echo "$name: no GitHub repo in the config, skipped"; continue; fi
  for l in "${LABELS[@]}"; do
    IFS='|' read -r old label color desc <<<"$l"
    if gh api -X PATCH "repos/$gh_repo/labels/$(uri "$old")" -f new_name="$label" -f color="$color" \
        -f description="$desc" >/dev/null 2>&1; then
      echo "$gh_repo: renamed $old to $label"
    elif gh api "repos/$gh_repo/labels" -f name="$label" -f color="$color" -f description="$desc" >/dev/null 2>&1; then
      echo "$gh_repo: created $label"
    elif gh api -X PATCH "repos/$gh_repo/labels/$(uri "$label")" -f color="$color" -f description="$desc" >/dev/null 2>&1; then
      echo "$gh_repo: updated $label"
    else
      echo "$gh_repo: FAILED $label"
      failed=1
    fi
  done
  for r in "${RETIRED[@]}"; do
    IFS='|' read -r old new <<<"$r"
    nums=$(gh api --paginate "repos/$gh_repo/issues?state=open&per_page=100&labels=$(uri "$old")" \
      --jq '.[] | select(.pull_request | not) | .number' 2>/dev/null) || continue  # the label is not there
    if [ -z "$new" ]; then
      [ -n "$nums" ] && echo "$gh_repo: open issues still in $old (the owner closes them):" $nums
      continue
    fi
    moved=1
    for n in $nums; do
      if gh api "repos/$gh_repo/issues/$n/labels" -f "labels[]=$new" >/dev/null 2>&1 &&
         gh api -X DELETE "repos/$gh_repo/issues/$n/labels/$(uri "$old")" >/dev/null 2>&1; then
        echo "$gh_repo: #$n moved from $old to $new"
      else
        echo "$gh_repo: FAILED to move #$n from $old to $new"; moved=0; failed=1
      fi
    done
    if [ "$moved" = 1 ] && gh api -X DELETE "repos/$gh_repo/labels/$(uri "$old")" >/dev/null 2>&1; then
      echo "$gh_repo: deleted the label $old"
    fi
  done
done
exit $failed
