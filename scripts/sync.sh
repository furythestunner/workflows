#!/bin/bash
# Brings one project repo's checkout up to this master copy's workflow. Run from anywhere:
#   bash scripts/sync.sh <path to the project checkout> [notes file]
# What it does in the project checkout (README.md, "How the sync works"):
#   - copies every committed file under .claude/ here, except this repo's own ground-truth.conf and settings.json;
#   - deletes files an earlier sync brought that are no longer here (the old .claude/workflow-manifest lists them);
#   - in .claude/settings.json, swaps the hooks that run synced hook files for the current ones and keeps the rest;
#   - writes .claude/workflow-manifest and .claude/workflow-version.
# It never touches CLAUDE.md, ground-truth.conf, notes/ or the project's own skills. Anything that needs a person
# (a new config key, the old rules block still in CLAUDE.md) goes into the notes file for the pull request.
set -euo pipefail
target=$(cd "${1:?usage: bash scripts/sync.sh <project checkout> [notes file]}" && pwd)
notes=${2:-/dev/null}
master=$(cd "$(dirname "$0")/.." && pwd)
cd "$master"

own='\.claude/(ground-truth\.conf|settings\.json|settings\.local\.json|workflow-manifest|workflow-version)'
mapfile -t files < <(git ls-files .claude | grep -vxE "$own")
declare -A current=()
for f in "${files[@]}"; do current[$f]=1; done
previous=()
note() { echo "- $*" >>"$notes"; }

# 1. Files an earlier sync brought that the master copy no longer has.
if [ -f "$target/.claude/workflow-manifest" ]; then
  while IFS= read -r f; do
    [[ -z $f || $f == \#* ]] && continue
    previous+=("$f")
    [ -n "${current[$f]:-}" ] && continue
    if [ -e "$target/$f" ]; then rm -f "$target/$f"; note "Removed \`$f\` (no longer in the workflow)."; fi
  done < <(tr -d '\r' <"$target/.claude/workflow-manifest")
  find "$target/.claude" -type d -empty -delete 2>/dev/null || true
fi

# Synced files the project edited since its last version: the copy below replaces those edits, so name them.
old=$(grep -oE '\b[0-9a-f]{7,40}\b' "$target/.claude/workflow-version" 2>/dev/null | head -1 || true)
if [ -n "$old" ] && git cat-file -e "$old^{commit}" 2>/dev/null; then
  for f in "${files[@]}"; do
    [ -f "$target/$f" ] || continue
    git cat-file -e "$old:$f" 2>/dev/null || continue
    if ! diff -q --strip-trailing-cr <(git show "$old:$f") "$target/$f" >/dev/null; then
      note "\`$f\` had edits made in this repo; the shared version replaces them. Anything project-specific in them belongs in CLAUDE.md."
    fi
  done
fi

# 2. Copy the synced files.
for f in "${files[@]}"; do
  mkdir -p "$target/$(dirname "$f")"
  cp "$f" "$target/$f"
done

# 3. settings.json: keep the project's keys and its own hooks, replace the hooks that run synced files.
SYNCED=$(printf '%s\n' "${files[@]}" "${previous[@]}") node "$master/scripts/sync-settings.mjs" \
  "$master/.claude/settings.json" "$target/.claude/settings.json"

# 4. Manifest and version.
{
  echo "# Files synced from github.com/furythestunner/workflows. Do not edit them here: the next sync undoes it."
  printf '%s\n' "${files[@]}"
} >"$target/.claude/workflow-manifest"
echo "workflows $(git rev-parse --short HEAD) $(git log -1 --format=%cs) (written by the sync; do not edit)" \
  >"$target/.claude/workflow-version"

# 5. What a person has to do before merging.
conf=$target/.claude/ground-truth.conf
if [ ! -f "$conf" ]; then
  cp .claude/ground-truth.conf "$conf"
  note "New \`.claude/ground-truth.conf\`, copied from the master copy: fill in REPOS, WORK_BRANCH, HANDOFF, DOCS and USER_NAME before merging."
else
  for k in $(grep -oE '^[A-Z_]+=' .claude/ground-truth.conf | tr -d =); do
    if ! grep -qE "^$k=" "$conf"; then
      note "\`.claude/ground-truth.conf\` has no \`$k\` yet (master copy: \`$(grep -E "^$k=" .claude/ground-truth.conf | cut -d= -f2-)\`); add it with this project's value."
    fi
  done
fi
if grep -q '^## Sessions and trackers' "$target/CLAUDE.md" 2>/dev/null; then
  note "CLAUDE.md still holds the old \"Sessions and trackers\" block. Those rules now come from \`.claude/rules/workflow.md\`: delete the block, and move any line in it that is specific to this project to another section of CLAUDE.md."
fi
exit 0
