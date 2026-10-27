// PreToolUse hook: every pull request gets a review before it opens (26 Oct 2026; rule since 23 Oct, enforced now).
// Blocks opening a pull request (the GitHub tools' create_pull_request, or gh pr create) until /code-review has run
// since the session's last pull request (or its start): Claude called the code-review skill, or the user typed
// /code-review. A guard against mistakes: it cannot tell whether the review covered the latest diff.
import { readFileSync } from 'node:fs';

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
const tool = input.tool_name || '';
const cmd = String(input.tool_input?.command ?? '');
const opens = /^mcp__.*github.*create_pull_request$/i.test(tool) ||
  (tool === 'Bash' && /(^|[;&|(\n]|\$\()\s*gh\s+pr\s+create\b/.test(cmd));
if (!opens || !input.transcript_path) process.exit(0);

let entries;
try {
  entries = readFileSync(input.transcript_path, 'utf8').split('\n').filter(Boolean).map(l => {
    try { return JSON.parse(l); } catch { return null; }
  }).filter(Boolean);
} catch { process.exit(0); }
const isPr = b => b.type === 'tool_use' && (/^mcp__.*github.*create_pull_request$/i.test(b.name || '') ||
  (b.name === 'Bash' && /(^|[;&|(\n]|\$\()\s*gh\s+pr\s+create\b/.test(String(b.input?.command ?? ''))));
// The call being checked may already be in the transcript: it is not an earlier pull request.
const prs = entries.flatMap(e => e.type === 'assistant' && Array.isArray(e.message?.content) ? e.message.content.filter(isPr) : []);
const current = input.tool_use_id ? prs.find(b => b.id === input.tool_use_id) : prs.at(-1);

// In order: a review sets it, an earlier pull request clears it, so each pull request needs its own review.
let reviewed = false;
for (const e of entries) {
  const c = e.message?.content;
  if (e.type === 'assistant' && Array.isArray(c)) for (const b of c) {
    if (b.type === 'tool_use' && b.name === 'Skill' && /(^|:)code-review$/.test(String(b.input?.skill ?? ''))) reviewed = true;
    if (isPr(b) && b !== current) reviewed = false;
  }
  if (e.type === 'user' && !e.isMeta) {
    const text = typeof c === 'string' ? c : Array.isArray(c) ? c.filter(b => b.type === 'text').map(b => b.text).join('\n') : '';
    if (/^\s*\/code-review\b|<command-name>\/?code-review<\/command-name>/m.test(text)) reviewed = true;
  }
}
if (reviewed) process.exit(0);

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'PreToolUse',
    permissionDecision: 'deny',
    permissionDecisionReason: 'Review guard: no /code-review since the last pull request (or the session start). Run it on the diff against main ' +
      '(the code-review skill), fix what it finds, and give each finding left as is a line in the pull request ' +
      'saying why (.claude/rules/workflow.md, "Every pull request gets a review and a watcher"). Then open it again.',
  },
}));
