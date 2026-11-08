#!/bin/bash
# Prints the CHANGES.md lines added since a commit, grouped for a pull request description. Used by sync-all.sh.
#   bash scripts/changes-since.sh <old commit> [repo dir, default: this repo]
# Prints nothing when no line was added (the caller then shows only the commit list).
set -uo pipefail
old=${1:?usage: bash scripts/changes-since.sh <old commit> [repo dir]}
dir=${2:-$(cd "$(dirname "$0")/.." && pwd)}

added=$(git -C "$dir" diff --no-color "$old" HEAD -- CHANGES.md 2>/dev/null |
  sed -n 's/^+- [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} //p')
[ -n "$added" ] || exit 0

group() { # <tag> <heading>
  local lines
  lines=$(printf '%s\n' "$added" | sed -n "s/^$1: */- /p")
  [ -n "$lines" ] && printf '### %s\n%s\n\n' "$2" "$lines"
}
group 'For you' 'Changes for you'
group 'New' 'New'
group 'Fixed' 'Fixed'
other=$(printf '%s\n' "$added" | grep -vE '^(For you|New|Fixed):' | sed 's/^/- /')
[ -n "$other" ] && printf '### Other\n%s\n\n' "$other"
exit 0
