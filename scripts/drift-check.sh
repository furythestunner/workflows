#!/bin/bash
# Which repos run an old copy of the workflow? Compares each repo's .claude/workflow-version with main here and
# lists the workflow commits it is missing. The weekly scheduled task "Workflow drift check" runs it.
#
# Usage, from a clone of this repo with full history:
#   bash scripts/drift-check.sh <name>=<path to that repo's .claude/workflow-version> ...
# Exit: 0 every repo current, 1 at least one behind, 2 a version that cannot be read or is not in main's history.
[ $# -gt 0 ] || { echo "usage: bash scripts/drift-check.sh <name>=<path to .claude/workflow-version> ..."; exit 2; }
start=$PWD
cd "$(dirname "$0")/.." || exit 2
ref=${DRIFT_REF:-origin/main}
# Paths that make up the workflow. ground-truth.conf holds this repo's own values, so a change there is not drift.
# Since the sync, a repo behind means its "Workflow update" pull request is waiting to be merged.
paths=(.claude cloud ':!.claude/ground-truth.conf')

head=$(git rev-parse --short "$ref" 2>/dev/null) || { echo "UNKNOWN  $ref not found; fetch it first"; exit 2; }
rc=0
for arg in "$@"; do
  name=${arg%%=*} file=${arg#*=}
  case $file in /*) ;; *) file=$start/$file ;; esac
  # The file reads like "workflows 4603484 2026-10-22 (master copy; ...)": the first 7-40 hex word is the commit.
  ver=$(grep -oE '\b[0-9a-f]{7,40}\b' "$file" 2>/dev/null | head -1)
  if [ -z "$ver" ]; then echo "UNKNOWN  $name: no commit in $file"; rc=2; continue; fi
  if ! git merge-base --is-ancestor "$ver" "$ref" 2>/dev/null; then
    echo "UNKNOWN  $name: $ver is not in the history of $ref"; rc=2; continue
  fi
  missing=$(git log --oneline --no-merges "$ver..$ref" -- "${paths[@]}")
  if [ -z "$missing" ]; then echo "current  $name ($ver)"; continue; fi
  echo "BEHIND   $name: $(wc -l <<<"$missing") workflow commits ($ver -> $head)"
  sed 's/^/           /' <<<"$missing"
  [ $rc -eq 0 ] && rc=1
done
exit $rc
