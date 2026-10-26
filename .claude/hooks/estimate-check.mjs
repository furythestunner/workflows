// Stop hook: Claude's time estimates ran 4 to 6 times too high (26 Oct 2026, corrected by the user more than once).
// When the last reply gives a time in minutes or hours and Claude did not read the measured rounds in
// notes/lessons.md this turn, Claude is sent back once to check the estimate against them. A nudge, not a guarantee:
// a time that is not an estimate of Claude's work (a clock time, the user's part) needs no change.
import { readFileSync } from 'node:fs';

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
if (input.stop_hook_active || !input.transcript_path) process.exit(0);

let entries;
try {
  entries = readFileSync(input.transcript_path, 'utf8').split('\n').filter(Boolean).map(l => {
    try { return JSON.parse(l); } catch { return null; }
  }).filter(Boolean);
} catch { process.exit(0); }

const blocks = e => Array.isArray(e.message?.content) ? e.message.content : [];
const text = e => typeof e.message?.content === 'string' ? e.message.content
  : blocks(e).filter(b => b.type === 'text').map(b => b.text).join('\n');
const isTurnStart = e => e.type === 'user' && !e.isMeta && text(e).trim() !== '';

let start = -1;
for (let i = entries.length - 1; i >= 0; i--) if (isTurnStart(entries[i])) { start = i; break; }
if (start < 0) process.exit(0);
const turn = entries.slice(start + 1);

const reply = turn.filter(e => e.type === 'assistant').map(text).join('\n');
const ESTIMATE = /\b\d+\s*(?:(?:to|-|–)\s*\d+\s*)?(?:min|mins|minutes?|h|hrs?|hours?)\b|\b\d+\s*(?:(?:-|–)\s*\d+\s*)?(?:perc|óra)/i;
if (!ESTIMATE.test(reply)) process.exit(0);

const readLessons = turn.some(e => e.type === 'assistant' && blocks(e).some(b => b.type === 'tool_use' &&
  /lessons\.md/.test(JSON.stringify(b.input || {}))));
if (readLessons) process.exit(0);

console.log(JSON.stringify({
  decision: 'block',
  reason: 'Estimate check: your reply gives a time. If it estimates your own work, read the measured rounds in ' +
    'notes/lessons.md and correct the estimate to match them (your estimates have run 4 to 6 times too high); ' +
    'with no similar round there, estimate low. Give the user\'s part (reviews, merges, clicks) separately. After ' +
    'the work, add the measured time there. If the time is not an estimate of your work (a clock time, a measured ' +
    'time, the user\'s part), stop now and add no text.'
}));
