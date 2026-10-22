#!/usr/bin/env bash
#
# labels.sh — creates the type:: and status:: issue labels in every GitHub repo of .claude/ground-truth.conf.
# Safe to run again: a label that exists is updated to the colour and description below. Other labels are left alone.
# The issue guard (.claude/hooks/issue-guard.mjs) lets this script through: creating a label applies it to nothing.
#
# Usage: bash .claude/skills/session-start/labels.sh

set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
REPOS=()
# shellcheck source=/dev/null
[ -f "$ROOT/.claude/ground-truth.conf" ] && . "$ROOT/.claude/ground-truth.conf"

LABELS=(
  "type::feature|1d76db|Something new"
  "type::bug|d73a4a|Something that does not work"
  "type::config|5319e7|A setting or a server, no code"
  "type::docs|0075ca|Writing only"
  "status::backlog|ededed|Not approved yet"
  "status::ready|0e8a16|Approved: only the owner sets this"
  "status::in-progress|fbca04|Claude is working on it"
  "status::blocked|b60205|Waiting for an answer (the question is on the issue)"
  "status::review|c5def5|A pull request is open: the owner tests and merges"
  "status::done|5a5a5a|Finished without a pull request: only the owner sets this"
)

failed=0
for spec in "${REPOS[@]}"; do
  IFS='|' read -r name _ _ _ gh_repo <<<"$spec"
  if [ -z "$gh_repo" ]; then echo "$name: no GitHub repo in the config, skipped"; continue; fi
  for l in "${LABELS[@]}"; do
    IFS='|' read -r label color desc <<<"$l"
    if gh api "repos/$gh_repo/labels" -f name="$label" -f color="$color" -f description="$desc" >/dev/null 2>&1; then
      echo "$gh_repo: created $label"
    elif gh api -X PATCH "repos/$gh_repo/labels/${label//:/%3A}" -f color="$color" -f description="$desc" >/dev/null 2>&1; then
      echo "$gh_repo: updated $label"
    else
      echo "$gh_repo: FAILED $label"
      failed=1
    fi
  done
done
exit $failed
