#!/usr/bin/env bash
#
# fence.sh — the file fence of a crew round (/crew, step 5). Lists every changed, new or deleted file in the working
# copy that the brief's "Files:" line does not allow. Run it after the implementer and before any review: a file
# outside the fence goes back to the implementer.
#
# "Files:" holds paths separated by spaces or commas. An entry ending in / allows everything under that folder; *
# and ? work as in bash. The round records in notes/crew/ are always allowed (the orchestrator writes them).
#
# Usage: bash .claude/skills/crew/fence.sh <round record>   (exit 0 = all inside, 1 = files outside, 2 = no fence)

set -uo pipefail
record=${1:-}
if [ -z "$record" ] || [ ! -f "$record" ]; then echo "fence: round record not found: $record" >&2; exit 2; fi

line=$(tr -d '\r' <"$record" | grep -m1 -E '^[[:space:]]*Files:' | sed -E 's/^[[:space:]]*Files:[[:space:]]*//')
read -r -a allowed <<<"$(printf '%s' "$line" | tr ',`' '  ')"
if [ ${#allowed[@]} -eq 0 ]; then echo "fence: no \"Files:\" line in $record" >&2; exit 2; fi

inside() { # <path>
  local a
  [[ $1 == notes/crew/* ]] && return 0
  for a in "${allowed[@]}"; do
    if [[ $a == */ ]]; then [[ $1 == "$a"* ]] && return 0
    else [[ $1 == $a ]] && return 0; fi  # unquoted: * and ? match
  done
  return 1
}

outside=0
# -z: paths with spaces arrive as they are; a rename gives the new path, then the old one as its own entry.
while IFS= read -r -d '' entry; do
  status=${entry:0:2} path=${entry:3}
  if ! inside "$path"; then echo "outside the fence: $path"; outside=1; fi
  if [[ $status == R* || $status == C* ]]; then
    IFS= read -r -d '' old
    if ! inside "$old"; then echo "outside the fence: $old (renamed)"; outside=1; fi
  fi
done < <(git status --porcelain -z -uall)

[ $outside -eq 0 ] && echo "fence: every changed file is inside"
exit $outside
