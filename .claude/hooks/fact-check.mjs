// Stop hook: claims about the repo are checked, not remembered (10 Nov 2026, Balázs).
// When Claude's reply this turn says the repo has or lacks something ("we already have X", "there is no X",
// "X does not exist") and Claude opened no file this turn (Read, Grep, Glob, or a Bash command that reads files),
// Claude is sent back once to open the file that shows it and correct the reply if it was wrong. The user cannot
// easily catch a wrong claim about the code, so the check sits on Claude's side. A nudge: when the claim is not
// about the repo, Claude stops without text.
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
let start = -1;
for (let i = entries.length - 1; i >= 0; i--) {
  const e = entries[i];
  if (e.type === 'user' && !e.isMeta && text(e).trim() !== '') { start = i; break; }
}
if (start < 0) process.exit(0);
const turn = entries.slice(start + 1).filter(e => e.type === 'assistant');

// Claims that the repo has or lacks something.
const CLAIM = new RegExp([
  String.raw`\balready (has|have|does|do|covers?|handles?|exists?|is in|are in|says?)\b`,
  String.raw`\b(doesn't|does not|don't|do not|never) (have|exist|cover|handle|say|mention)\b`,
  String.raw`\bthere (is|are) no\b`, String.raw`\bthere's no\b`,
  String.raw`\bnothing in the (repo|code|setup|workflow|rules)\b`,
].join('|'), 'i');
const reply = turn.map(text).join('\n').replace(/```[\s\S]*?```/g, '').replace(/`[^`\n]*`/g, '`x`');
const claim = reply.split(/(?<=[.!?:])\s+|\n/).find(s => CLAIM.test(s));
if (!claim) process.exit(0);

// Did Claude open a file this turn?
const READS = /\b(cat|grep|rg|sed|awk|head|tail|less|ls|find|wc|diff|jq)\b|\bgit (show|log|diff|grep|ls-files|blame)\b/;
const checked = turn.some(e => blocks(e).some(b => b.type === 'tool_use' && (
  ['Read', 'Grep', 'Glob'].includes(b.name) ||
  (b.name === 'Bash' && READS.test(String(b.input?.command ?? ''))))));
if (checked) process.exit(0);

const short = claim.trim().length > 120 ? claim.trim().slice(0, 117) + '...' : claim.trim();
console.log(JSON.stringify({
  decision: 'block',
  reason: 'Fact check (.claude/hooks/fact-check.mjs): your reply says "' + short + '", but you opened no file ' +
    'this turn. If it is about this repo, open the file that shows it now (a memory from earlier in the session ' +
    'is not enough) and cite it as `file:line`; if the claim was wrong, say so and correct it in one or two lines. ' +
    'If it is not about the repo, stop without text.',
}));
