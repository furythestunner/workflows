#!/bin/bash
# Opens or updates one "Workflow update" pull request in every repo of sync/repos.txt (or only the repos given as
# arguments). Run by .github/workflows/sync.yml; GH_TOKEN needs Contents and Pull requests write access to them.
set -uo pipefail
master=$(cd "$(dirname "$0")/.." && pwd)
head=$(git -C "$master" rev-parse --short HEAD)
work=$(mktemp -d)
rc=0
if [ $# -gt 0 ]; then repos=("$@"); else mapfile -t repos < <(grep -vE '^[[:space:]]*(#|$)' "$master/sync/repos.txt"); fi

for repo in "${repos[@]}"; do
  echo "::group::$repo"
  dir=$work/${repo//\//_}
  if ! git clone -q "https://x-access-token:${GH_TOKEN}@github.com/$repo.git" "$dir"; then
    echo "::error::$repo: cannot clone it (is it in the token's repository list?)"; rc=1; echo "::endgroup::"; continue
  fi
  cd "$dir" || continue

  # The pull request goes to the work branch, where the sessions run; the default branch when there is none.
  # Read from the default branch's config; a repo without one there gets a warning, never a silent fallback.
  base=$(tr -d '\r' <.claude/ground-truth.conf 2>/dev/null |
    sed -n 's/^WORK_BRANCH="\{0,1\}\([^"#[:space:]]*\).*/\1/p' | head -1)
  if [ -z "$base" ] || ! git ls-remote --exit-code --heads origin "$base" >/dev/null; then
    echo "::warning::$repo: no WORK_BRANCH on GitHub (${base:-none in .claude/ground-truth.conf on the default branch}); the pull request goes to the default branch"
    base=$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')
  fi
  git checkout -q "$base"
  old=$(grep -oE '\b[0-9a-f]{7,40}\b' .claude/workflow-version 2>/dev/null | head -1)
  # An open sync branch with hand commits (e.g. CLAUDE.md moved in the same pull request) is built on, not reset.
  push=(-f)
  if git rev-parse -q --verify origin/workflow-sync >/dev/null &&
     [ -n "$(git log --format=%an "$base..origin/workflow-sync" | grep -vx 'workflows sync')" ]; then
    git checkout -q -B workflow-sync origin/workflow-sync
    if ! git merge -q --no-edit "$base" >/dev/null; then
      echo "::error::$repo: the open sync pull request has hand edits that conflict with $base; merge or close it first"
      rc=1; cd "$master" || exit 1; echo "::endgroup::"; continue
    fi
    push=()
  else
    git checkout -q -B workflow-sync
  fi

  notes=$work/notes.md; : >"$notes"
  if ! bash "$master/scripts/sync.sh" "$dir" "$notes"; then
    echo "::error::$repo: sync.sh failed"; rc=1; cd "$master"; echo "::endgroup::"; continue
  fi
  git add -A .claude
  if git diff --cached --quiet -- . ':!.claude/workflow-version'; then
    echo "$repo ($base): already current"; cd "$master"; echo "::endgroup::"; continue
  fi
  git -c user.name="workflows sync" -c user.email="workflows-sync@users.noreply.github.com" \
    commit -q -m "Workflow update to furythestunner/workflows $head"
  if ! git push -q "${push[@]}" origin workflow-sync; then
    echo "::error::$repo: cannot push the workflow-sync branch (token rights or a branch rule)"; rc=1
    cd "$master" || exit 1; echo "::endgroup::"; continue
  fi

  body=$work/body.md
  {
    echo "Brings this repo's workflow (skills, agents, hooks, shared rules) up to furythestunner/workflows \`$head\`."
    echo "Opened by the sync. Merging it is the whole update."
    echo
    echo "## What changed in the workflow"
    if [ -n "$old" ] && git -C "$master" merge-base --is-ancestor "$old" HEAD 2>/dev/null; then
      git -C "$master" log --no-merges --format='- %s (`%h`)' "$old..HEAD" -- .claude cloud | head -40
    else
      echo "- First sync (the repo was on \`${old:-no version}\`): every shared file is replaced by the master copy."
    fi
    if [ -s "$notes" ]; then echo; echo "## Do before merging"; cat "$notes"; fi
    echo
    echo "## Check after merging"
    echo "Start a new session on \`$base\`: the first reply must open with the brief."
  } >"$body"

  num=$(gh pr list -R "$repo" --head workflow-sync --base "$base" --state open --json number --jq '.[0].number // empty')
  if [ -n "$num" ]; then
    if gh pr edit "$num" -R "$repo" --title "Workflow update ($head)" --body-file "$body" >/dev/null; then
      echo "$repo: updated #$num"
    else
      echo "::error::$repo: cannot update pull request #$num"; rc=1
    fi
  else
    gh pr create -R "$repo" --base "$base" --head workflow-sync --title "Workflow update ($head)" --body-file "$body" || rc=1
  fi
  cd "$master" || exit 1
  echo "::endgroup::"
done
exit $rc
