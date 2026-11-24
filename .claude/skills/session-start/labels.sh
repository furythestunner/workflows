#!/usr/bin/env bash
#
# labels.sh: creates the "Type: x" and "Status: x" issue labels in every GitHub repo of .claude/ground-truth.conf,
# or in the repos named on the command line.
# Safe to run again: a label that exists is updated to the colour and description below. A label under its old name
# ("status::ready", until 22 Oct 2026) is renamed; when the new name already exists, its open issues move to the new
# one and the old label is deleted, so every issue keeps its status. The statuses dropped on 10 Nov 2026 (Blocked,
# Review) are moved to the ones that stay and deleted. GitHub's default labels (bug, enhancement...) are deleted
# (ruling 24 Nov 2026: only our own labels). "Status: Done" stays for the owner: the issue guard keeps it blocked.
# Other labels are left alone. Needs only gh (no jq).
# The issue guard (.claude/hooks/issue-guard.mjs) lets this script through: creating a label applies it to nothing.
#
# Usage: bash .claude/skills/session-start/labels.sh                 every GitHub repo in the config
#        bash .claude/skills/session-start/labels.sh owner/repo ...  only these repos

set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
REPOS=()
if [ $# -gt 0 ]; then
  for r in "$@"; do REPOS+=("$r||||$r"); done
else
  # shellcheck source=/dev/null
  [ -f "$ROOT/.claude/ground-truth.conf" ] && . "$ROOT/.claude/ground-truth.conf"
fi

LABELS=(
  "type::feature|Type: Feature|1d76db|Something new"
  "type::bug|Type: Bug|d73a4a|Something that does not work"
  "type::config|Type: Config|5319e7|A setting or a server, no code"
  "type::docs|Type: Docs|0075ca|Writing only"
  "status::backlog|Status: Backlog|ededed|Not approved yet, has a question for the owner, or on hold"
  "status::ready|Status: Ready|0e8a16|Approved: only the owner sets this"
  "status::in-progress|Status: In progress|fbca04|Claude is working on it, until its pull request is merged"
)
# Labels that go: open issues move to the label on the right, then the label is deleted. Statuses dropped on
# 10 Nov 2026 (three are enough for one person), and the old names left behind when the new name already existed.
# "Status: Done" issues are only listed: the owner closes them and deletes the label.
RETIRED=(
  "Status: Blocked|Status: Backlog"
  "Status: Review|Status: In progress"
  "status::blocked|Status: Backlog"
  "status::review|Status: In progress"
  "Status: Done|"
)
for l in "${LABELS[@]}"; do IFS='|' read -r old label _ <<<"$l"; RETIRED+=("$old|$label"); done
# GitHub's default labels, deleted outright (ruling 24 Nov 2026): the Type: labels do the same job.
DEFAULTS=(bug documentation duplicate enhancement "good first issue" "help wanted" invalid question wontfix accessibility)

# URL-encodes a label name byte by byte (so accents work too), without jq.
uri() {
  local LC_ALL=C s=$1 out='' c h i
  for ((i = 0; i < ${#s}; i++)); do
    c=${s:i:1}
    case $c in
      [A-Za-z0-9._~-]) out+=$c ;;
      *) printf -v h '%%%02X' "'$c"; out+=$h ;;
    esac
  done
  printf '%s' "$out"
}
# Open issue numbers (not pull requests) with the label $2 in repo $1. Returns 1 if the label is not there, and 2
# (with a FAILED line) if the list could not be read, so a network error never passes for "no such label".
open_issues() {
  gh api "repos/$1/labels/$(uri "$2")" >/dev/null 2>&1 || return 1
  gh api --paginate "repos/$1/issues?state=open&per_page=100&labels=$(uri "$2")" \
    --jq '.[] | select(.pull_request | not) | .number' && return 0
  echo "$1: FAILED to list the open issues in $2" >&2; return 2
}

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
    nums=$(open_issues "$gh_repo" "$old"); rc=$?
    [ "$rc" = 2 ] && failed=1
    [ "$rc" = 0 ] || continue  # the label is not there, or its issues could not be read
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
  for d in "${DEFAULTS[@]}"; do
    nums=$(open_issues "$gh_repo" "$d"); rc=$?
    [ "$rc" = 2 ] && failed=1
    [ "$rc" = 0 ] || continue  # the label is not there, or its issues could not be read
    [ -n "$nums" ] && echo "$gh_repo: open issues lose the label $d (check their Type: label):" $nums
    if gh api -X DELETE "repos/$gh_repo/labels/$(uri "$d")" >/dev/null 2>&1; then
      echo "$gh_repo: deleted the label $d"
    else
      echo "$gh_repo: FAILED to delete the label $d"; failed=1
    fi
  done
done
exit $failed
