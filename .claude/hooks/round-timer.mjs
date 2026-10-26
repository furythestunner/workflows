// Stop hook: time estimates come from measured rounds, not from feel (26 Oct 2026). Estimates by feel ran 4 to 6
// times too high, and the estimate check that sent Claude back to read them fired on every time in a reply. This
// measures instead: when a turn made a commit that is not docs only, it appends one line to notes/rounds.md, from
// the user's message to the end of the reply, with the commits. session-start.sh prints the latest rounds, so every
// estimate has them at hand. Never sends Claude back; anything it cannot read is skipped silently.
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { execFileSync } from 'node:child_process';

const root = process.env.CLAUDE_PROJECT_DIR || '.';
const ROUNDS = 'notes/rounds.md';
const HEADER = '# Measured rounds\n\nWritten by `.claude/hooks/round-timer.mjs`: one line per reply that made a code commit, from the\n' +
  'user\'s message to the end of the reply. Size Claude\'s own work from these, never by feel. Committed with the docs.\n\n';

let conf = '';
try { conf = readFileSync(join(root, '.claude/ground-truth.conf'), 'utf8'); } catch {}
const docs = ((conf.match(/^DOCS="([^"]*)"/m) || [])[1] ?? 'notes BACKLOG.md questions.md CLAUDE.md README.md')
  .split(/\s+/).filter(Boolean);

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
// A second stop (another hook sent Claude back) belongs to the round already measured at the first one.
if (input.stop_hook_active || !input.transcript_path) process.exit(0);

let entries;
try {
  entries = readFileSync(input.transcript_path, 'utf8').split('\n').filter(Boolean).map(l => {
    try { return JSON.parse(l); } catch { return null; }
  }).filter(Boolean);
} catch { process.exit(0); }

// The user's last typed message: not a tool result, not hook feedback (isMeta), not a GitHub event.
const text = e => typeof e.message?.content === 'string' ? e.message.content
  : Array.isArray(e.message?.content) ? e.message.content.filter(b => b.type === 'text').map(b => b.text).join('\n') : '';
const start = [...entries].reverse().find(e => e.type === 'user' && !e.isMeta &&
  (!e.origin || e.origin.kind === 'human') && text(e).trim() && e.timestamp);
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

const pad = n => String(n).padStart(2, '0');
const when = `${t0.getFullYear()}-${pad(t0.getMonth() + 1)}-${pad(t0.getDate())}`;
let what = subjects.join('; ');
if (what.length > 140) what = what.slice(0, 137) + '...';
const line = `- ${when}: ${Math.max(min, 1)} min, ${subjects.length} commit${subjects.length > 1 ? 's' : ''}: ${what}\n`;

const file = join(root, ROUNDS);
try {
  mkdirSync(dirname(file), { recursive: true });
  const old = existsSync(file) ? readFileSync(file, 'utf8') : HEADER;
  writeFileSync(file, old + (old.endsWith('\n') ? '' : '\n') + line);
} catch {}
