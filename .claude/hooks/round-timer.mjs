// Stop hook: time estimates come from measured rounds, not from feel (26 Oct 2026). Estimates by feel ran 4 to 6
// times too high, and the estimate check that sent Claude back to read them fired on every time in a reply. This
// measures instead: when a turn made a commit that is not docs only, it appends one line to notes/rounds.md, from
// the message that started the turn to the end of the reply, with the commits, and sends Claude back once to commit
// it (an uncommitted file is lost with a cloud container and stops the PC's start from updating the branch).
// session-start.sh prints the latest rounds, so every estimate has them at hand. Anything it cannot read is skipped.
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { execFileSync } from 'node:child_process';

const root = process.env.CLAUDE_PROJECT_DIR || '.';
const ROUNDS = 'notes/rounds.md';
const HEADER = '# Measured rounds\n\nWritten by `.claude/hooks/round-timer.mjs`: one line per reply that made a code commit, from the\n' +
  'message that started the turn to the end of the reply. Size Claude\'s own work from these, never by feel.\n\n';

let conf = '';
try { conf = readFileSync(join(root, '.claude/ground-truth.conf'), 'utf8'); } catch {}
const confVar = (k, d) => (conf.match(new RegExp('^' + k + '="([^"]*)"', 'm')) || [])[1] ?? d;
// The round file and the handoff never count as work, whatever DOCS says: committing them is not a round.
const docs = [...confVar('DOCS', 'notes BACKLOG.md questions.md CLAUDE.md README.md').split(/\s+/).filter(Boolean),
  ROUNDS, confVar('HANDOFF', 'notes/handoff.md')];

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
if (!input.transcript_path) process.exit(0);

let entries;
try {
  entries = readFileSync(input.transcript_path, 'utf8').split('\n').filter(Boolean).map(l => {
    try { return JSON.parse(l); } catch { return null; }
  }).filter(Boolean);
} catch { process.exit(0); }

// The message that started this turn: typed by the user or a GitHub event; not a tool result, not hook feedback.
const text = e => typeof e.message?.content === 'string' ? e.message.content
  : Array.isArray(e.message?.content) ? e.message.content.filter(b => b.type === 'text').map(b => b.text).join('\n') : '';
const start = [...entries].reverse().find(e => e.type === 'user' && !e.isMeta && text(e).trim() && e.timestamp);
if (!start) process.exit(0);
const t0 = new Date(start.timestamp);
if (isNaN(t0)) process.exit(0);
const now = input.now ? new Date(input.now) : new Date();  // input.now: tests only
const min = Math.round((now - t0) / 60000);

// Commits made since the message, with the ones that touch only docs left out.
let subjects;
try {
  subjects = execFileSync('git', ['log', '--no-merges', `--since=${t0.toISOString()}`, '--format=%s', 'HEAD', '--', '.',
    ...docs.map(d => `:(exclude)${d}`)], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })
    .split('\n').filter(Boolean).reverse();
} catch { process.exit(0); }
if (!subjects.length) process.exit(0);

// The turn's start time (UTC) keys the line: a second stop of the same turn (another hook sent Claude back) does
// not write it twice, but still writes it when the commit came only after that hook.
const when = t0.toISOString().slice(0, 16).replace('T', ' ') + ' UTC';
let what = subjects.join('; ');
if (what.length > 140) what = what.slice(0, 137) + '...';
const line = `- ${when}: ${Math.max(min, 1)} min, ${subjects.length} commit${subjects.length > 1 ? 's' : ''}: ${what}\n`;

const file = join(root, ROUNDS);
try {
  mkdirSync(dirname(file), { recursive: true });
  const old = existsSync(file) ? readFileSync(file, 'utf8') : HEADER;
  if (old.includes(`- ${when}:`)) process.exit(0);
  writeFileSync(file, old + (old.endsWith('\n') ? '' : '\n') + line);
} catch { process.exit(0); }
if (input.stop_hook_active) process.exit(0);  // never sent back twice: the next round's commit carries the line

console.log(JSON.stringify({
  decision: 'block',
  reason: `Round timer: this round (${Math.max(min, 1)} min) is now in ${ROUNDS}. Commit that file alone ` +
    `(git commit -m "Measured round" -- ${ROUNDS}); push it if this round's commits are pushed, otherwise it goes ` +
    'with your next push. Add no text for the user.',
}));
