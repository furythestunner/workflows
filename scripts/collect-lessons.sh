#!/bin/bash
# Collects the shared lessons of every repo in sync/repos.txt (or the repos given as arguments): the bullets under
# "## Shared" in each repo's notes/lessons.md on its work branch. New ones (not yet in .claude/rules/shared-lessons.md,
# spaces and case ignored) are appended there, and one "Shared lessons from the repos" pull request to main is opened
# or updated. Merging it starts the sync, which brings the file to every repo; there the lesson check
# (.claude/hooks/lesson-check.mjs) has Claude delete the copies that arrived.
# Run by .github/workflows/collect-lessons.yml. REPOS_TOKEN reads the repos (the sync's token); GH_TOKEN writes here.
# By hand, without opening a pull request:  DRY_RUN=1 REPOS_TOKEN=... bash scripts/collect-lessons.sh
set -uo pipefail
master=$(cd "$(dirname "$0")/.." && pwd)
cd "$master" || exit 1
shared=.claude/rules/shared-lessons.md
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
if [ $# -gt 0 ]; then repos=("$@"); else mapfile -t repos < <(grep -vE '^[[:space:]]*(#|$)' sync/repos.txt); fi
read_gh() { GH_TOKEN=${REPOS_TOKEN:-${GH_TOKEN:-}} gh api "$1" --jq .content 2>/dev/null | base64 -d 2>/dev/null; }

files=()
for repo in "${repos[@]}"; do
  conf=$(read_gh "repos/$repo/contents/.claude/ground-truth.conf")
  base=$(printf '%s\n' "$conf" | tr -d '\r' | sed -n 's/^WORK_BRANCH="\{0,1\}\([^"#[:space:]]*\).*/\1/p' | head -1)
  out="$work/${repo//\//_}.md"
  if read_gh "repos/$repo/contents/notes/lessons.md${base:+?ref=$base}" >"$out" && [ -s "$out" ]; then
    echo "$repo (${base:-default branch}): read notes/lessons.md"
    files+=("$repo=$out")
  else
    echo "::warning::$repo: cannot read notes/lessons.md (${base:-default branch}); skipped"
  fi
done

added=$(node - "$shared" "${files[@]}" <<'EOF'
const fs = require('fs');
const [shared, ...pairs] = process.argv.slice(2);
const norm = t => t.replace(/\s+/g, ' ').trim().toLowerCase();
// Bullets with their raw lines and the heading above them (same rules as lesson-check.mjs)
function bullets(text) {
  const out = []; let heading = '', cur = null;
  for (const line of text.replace(/\r/g, '').split('\n')) {
    if (/^#{1,6}\s/.test(line)) { heading = line; cur = null; continue; }
    if (/^\s*-\s+/.test(line) && !/^\s{2,}-/.test(line)) { cur = { heading, lines: [line] }; out.push(cur); continue; }
    if (cur && /^\s+\S/.test(line)) { cur.lines.push(line); continue; }
    cur = null;
  }
  return out.map(b => ({ heading: b.heading, raw: b.lines.join('\n'),
    key: norm(b.lines.join(' ').replace(/^\s*-\s+/, '')) }));
}
let text = fs.readFileSync(shared, 'utf8');
const have = new Set(bullets(text).map(b => b.key));
const add = [];
for (const pair of pairs) {
  const i = pair.indexOf('='); const repo = pair.slice(0, i);
  for (const b of bullets(fs.readFileSync(pair.slice(i + 1), 'utf8'))) {
    if (!/^##\s+Shared\b/i.test(b.heading) || have.has(b.key)) continue;
    have.add(b.key); add.push({ repo, raw: b.raw });
  }
}
if (add.length) {
  const head = '## New from the repos (move each into its section)';
  if (!text.includes(head)) text = text.replace(/\s*$/, '\n\n' + head + '\n');
  text = text.replace(/\s*$/, '\n' + add.map(a => a.raw).join('\n') + '\n');
  fs.writeFileSync(shared, text);
}
for (const a of add) console.log('- ' + a.repo + ': ' + a.raw.replace(/^\s*-\s+/, '').replace(/\s+/g, ' ').slice(0, 160));
EOF
) || { echo "::error::could not merge the lessons"; exit 1; }

if [ -z "$added" ]; then echo "No new shared lessons."; exit 0; fi
echo "New shared lessons:"; echo "$added"
[ -n "${DRY_RUN:-}" ] && { echo "DRY_RUN: $shared changed here, no pull request."; exit 0; }

branch=lessons-collect
git -c user.name="workflows lessons" -c user.email="workflows-lessons@users.noreply.github.com" \
  checkout -q -B "$branch" &&
git add "$shared" &&
git -c user.name="workflows lessons" -c user.email="workflows-lessons@users.noreply.github.com" \
  commit -q -m "Shared lessons from the repos" &&
git push -q -f origin "$branch" || { echo "::error::cannot push $branch"; exit 1; }

body=$work/body.md
{
  echo "Lessons the repos marked as shared (\"## Shared\" in their \`notes/lessons.md\`), added to \`$shared\`."
  echo "Opened by the lesson collector. Before merging, move each line from \"New from the repos\" into its section"
  echo "(or edit it here); merging starts the sync, which brings the file to every repo."
  echo
  echo "## New lessons"
  echo "$added"
} >"$body"
num=$(gh pr list --head "$branch" --base main --state open --json number --jq '.[0].number // empty')
if [ -n "$num" ]; then gh pr edit "$num" --title "Shared lessons from the repos" --body-file "$body" >/dev/null && echo "updated #$num"
else gh pr create --base main --head "$branch" --title "Shared lessons from the repos" --body-file "$body"; fi
