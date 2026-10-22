// Stop hook: decisions made in the chat go into the trackers, not only into the chat (20 Oct 2026).
// If this turn the user answered a multiple-choice question or used decision words, and Claude did not touch
// questions.md, CLAUDE.md or notes/lessons.md and opened no GitHub issue, Claude is sent back once to record it. A nudge, not a
// guarantee: it cannot tell a ruling from a choice for the task at hand, so Claude decides and may skip.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

// WORK_BRANCH and USER_NAME come from .claude/ground-truth.conf (plain bash assignments).
let conf = '';
try { conf = readFileSync(join(process.env.CLAUDE_PROJECT_DIR || '.', '.claude/ground-truth.conf'), 'utf8'); } catch {}
const confVar = (k, d) => (conf.match(new RegExp('^' + k + '="([^"]*)"', 'm')) || [])[1] || d;
const branch = confVar('WORK_BRANCH', 'the work branch');
const who = confVar('USER_NAME', 'the user');

const input = JSON.parse(readFileSync(0, 'utf8') || '{}');
if (input.stop_hook_active || !input.transcript_path) process.exit(0);

let entries;
try {
  entries = readFileSync(input.transcript_path, 'utf8').split('\n').filter(Boolean).map(l => {
    try { return JSON.parse(l); } catch { return null; }
  }).filter(Boolean);
} catch { process.exit(0); }

const blocks = e => Array.isArray(e.message?.content) ? e.message.content : [];
const userText = e => {
  const c = e.message?.content;
  if (typeof c === 'string') return c;
  return blocks(e).filter(b => b.type === 'text').map(b => b.text).join('\n');
};
const isTurnStart = e => e.type === 'user' && !e.isMeta && userText(e).trim() !== '';

let start = -1;
for (let i = entries.length - 1; i >= 0; i--) if (isTurnStart(entries[i])) { start = i; break; }
if (start < 0) process.exit(0);
const turn = entries.slice(start);

const DECISION_WORDS = /\b(from now on|decided|decision|ruling|we'll always|never again)\b|mostantól|döntés|döntöttem|döntöttünk|szabály|legyen így/i;
const TRACKERS = /(questions\.md|BACKLOG\.md|CLAUDE\.md|lessons\.md)/;
const NEW_ISSUE = /\bgh\s+issue\s+create\b/;

const toolUses = turn.flatMap(e => e.type === 'assistant' ? blocks(e).filter(b => b.type === 'tool_use') : []);
const asked = toolUses.some(b => b.name === 'AskUserQuestion');
const said = DECISION_WORDS.test(userText(entries[start]));
const recorded = toolUses.some(b =>
  (['Edit', 'Write', 'MultiEdit'].includes(b.name) && TRACKERS.test(b.input?.file_path || '')) ||
  (b.name === 'Bash' && (TRACKERS.test(b.input?.command || '') || NEW_ISSUE.test(b.input?.command || ''))) ||
  (/^mcp__.*github.*issue_write$/i.test(b.name) && b.input?.method === 'create'));

if ((asked || said) && !recorded) {
  console.log(JSON.stringify({
    decision: 'block',
    reason: 'Decision check: this turn ' + who + ' ' + (asked ? 'answered a multiple-choice question' : 'used decision words') +
      ' and no tracker was touched. If it set something for the future (how a feature must work, a deliberate non-fix, ' +
      'a workflow rule), record it now: a ruling in questions.md §2 (🟢, date, ' + who + '’s words), new open work as a GitHub issue (status::backlog and one type:: label), ' +
      'a rule for Claude in CLAUDE.md; then commit and push the docs to ' + branch + ' (handoff rule). If it was only a ' +
      'choice for the task at hand, stop now and add no text.'
  }));
}
