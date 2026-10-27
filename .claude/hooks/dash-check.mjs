// UserPromptSubmit hook: no em dashes when the project asks for none (26 Oct 2026). If the repo's CLAUDE.md says
// "no em dashes" and Claude's previous reply used one, Claude is reminded before it answers the new message. A reply
// already shown cannot be changed, so this costs no extra turn; it only keeps the next reply clean.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
let rules = '';
try { rules = readFileSync(join(process.env.CLAUDE_PROJECT_DIR || input.cwd || '.', 'CLAUDE.md'), 'utf8'); } catch {}
if (!/\bno em[ -]?dash/i.test(rules) || !input.transcript_path) process.exit(0);

let entries;
try {
  entries = readFileSync(input.transcript_path, 'utf8').split('\n').filter(Boolean).map(l => {
    try { return JSON.parse(l); } catch { return null; }
  }).filter(Boolean);
} catch { process.exit(0); }

const text = e => typeof e.message?.content === 'string' ? e.message.content
  : Array.isArray(e.message?.content) ? e.message.content.filter(b => b.type === 'text').map(b => b.text).join('\n') : '';
const isTurnStart = e => e.type === 'user' && !e.isMeta && text(e).trim() !== '';
// The previous reply: Claude's text after the last message, leaving out the new one if it is already written (the
// same text as the prompt, with no reply after it).
const starts = entries.map((e, i) => isTurnStart(e) ? i : -1).filter(i => i >= 0);
let end = entries.length;
const last = starts.at(-1);
if (last !== undefined && text(entries[last]).trim() === String(input.prompt ?? '').trim() &&
    !entries.slice(last + 1).some(e => e.type === 'assistant')) end = starts.pop();
if (!starts.length) process.exit(0);
const reply = entries.slice(starts.at(-1) + 1, end).filter(e => e.type === 'assistant').map(text).join('\n');
if (!reply.includes('\u2014')) process.exit(0);

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    additionalContext: 'Dash check (.claude/hooks/dash-check.mjs): your previous reply used an em dash (—); ' +
      'CLAUDE.md says none. Write this reply without them: a comma, a colon, brackets or a new sentence instead.',
  },
}));
