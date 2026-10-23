#!/bin/bash
# Builds one zip per general-purpose skill, for upload to claude.ai (Settings, Capabilities, Skills). Uploaded
# skills reach every chat and cloud session on the account, so they need no copy in each repo.
# Usage: bash scripts/package-skills.sh   -> dist/claude-ai-skills/<skill>.zip
# Each zip holds <skill>/SKILL.md and <skill>/LICENSE.txt (the MIT notice from .claude/skills/THIRD-PARTY.md).
cd "$(dirname "$0")/.." || exit 1
command -v zip >/dev/null || { echo "zip is not installed (Windows: run it in a cloud session or WSL)"; exit 1; }
skills=(grill-me wait-what pr-body diagnosing-bugs questionnaire)
out=dist/claude-ai-skills
rm -rf "$out" && mkdir -p "$out"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
for s in "${skills[@]}"; do
  [ -f ".claude/skills/$s/SKILL.md" ] || { echo "missing .claude/skills/$s/SKILL.md"; exit 1; }
  mkdir -p "$tmp/$s"
  cp -r ".claude/skills/$s/." "$tmp/$s/"
  cp .claude/skills/THIRD-PARTY.md "$tmp/$s/LICENSE.txt"
  (cd "$tmp" && zip -qr "$OLDPWD/$out/$s.zip" "$s") || { echo "zip failed for $s"; exit 1; }
  echo "$out/$s.zip"
done
