#!/bin/bash
# Deletes merged feature branches (<WORK_BRANCH>-<topic>) on GitHub in every repo of sync/repos.txt, or only in the
# repos given as arguments. Run once an hour by .github/workflows/branch-cleanup.yml (README.md, "Delete merged
# branches by themselves"). The project repos are private on the free plan: there GitHub's own "Automatically
# delete head branches" would also delete the work branch, because rulesets are not enforced.
# A branch goes only when all of this holds:
#   - its name starts with the repo's WORK_BRANCH and a dash (from .claude/ground-truth.conf on the default branch),
#     so the default branch, the work branch and any other branch never match;
#   - a pull request from it was merged;
#   - it has no commit that is not in the default branch (nothing added after the merge, nothing unmerged).
# A deleted branch comes back with the "Restore branch" button on its pull request.
# Usage: bash scripts/branch-cleanup.sh [--dry-run] [owner/repo ...]
# GH_TOKEN needs Contents write and Pull requests read on the repos; repos of OWN_OWNER use GH_TOKEN_OWN (as in
# scripts/sync-all.sh). Without GH_TOKEN, gh uses its own login (a run by hand on the PC).
set -uo pipefail
master=$(cd "$(dirname "$0")/.." && pwd)
dry=0
[ "${1:-}" = "--dry-run" ] && { dry=1; shift; }
other_token=${GH_TOKEN:-}
if [ $# -gt 0 ]; then repos=("$@"); else mapfile -t repos < <(grep -vE '^[[:space:]]*(#|$)' "$master/sync/repos.txt" | tr -d '\r'); fi
rc=0

for repo in "${repos[@]}"; do
  token=$other_token
  if [ -n "${OWN_OWNER:-}" ] && [ "${repo%%/*}" = "$OWN_OWNER" ]; then token=${GH_TOKEN_OWN:-}; fi
  if [ -n "$token" ]; then export GH_TOKEN=$token; else unset GH_TOKEN; fi

  if ! default=$(gh api "repos/$repo" --jq .default_branch 2>/dev/null) || [ -z "$default" ]; then
    echo "::error::$repo: cannot read it (is it in the token's repository list?)"; rc=1; continue
  fi
  work=$(gh api -H 'Accept: application/vnd.github.raw' "repos/$repo/contents/.claude/ground-truth.conf?ref=$default" 2>/dev/null |
    tr -d '\r' | sed -n 's/^WORK_BRANCH="\{0,1\}\([^"#[:space:]]*\).*/\1/p' | head -1)
  if [ -z "$work" ]; then echo "$repo: no WORK_BRANCH on $default, skipped"; continue; fi

  if ! branches=$(gh api --paginate "repos/$repo/branches?per_page=100" --jq '.[].name' 2>/dev/null); then
    echo "::error::$repo: cannot list its branches"; rc=1; continue
  fi
  deleted=0 kept=0
  while IFS= read -r b; do
    [[ -n $b && $b == "$work"-* ]] || continue
    merged=$(gh api "repos/$repo/pulls?state=closed&per_page=100&head=${repo%%/*}:$b" \
      --jq '[.[] | select(.merged_at != null)] | length' 2>/dev/null)
    if [ "${merged:-0}" = 0 ]; then echo "$repo: $b kept (no merged pull request)"; kept=$((kept + 1)); continue; fi
    ahead=$(gh api "repos/$repo/compare/$default...$b" --jq .ahead_by 2>/dev/null)
    if [ "$ahead" != 0 ]; then
      echo "$repo: $b kept (${ahead:-unknown} commit(s) not in $default)"; kept=$((kept + 1)); continue
    fi
    if [ "$dry" = 1 ]; then echo "$repo: $b would be deleted"; deleted=$((deleted + 1)); continue; fi
    if gh api -X DELETE "repos/$repo/git/refs/heads/$b" >/dev/null 2>&1; then
      echo "$repo: $b deleted"; deleted=$((deleted + 1))
    else
      echo "::error::$repo: could not delete $b"; rc=1
    fi
  done <<<"$branches"
  echo "$repo: $deleted deleted$([ "$dry" = 1 ] && echo ' (dry run)'), $kept kept"
done
exit $rc
