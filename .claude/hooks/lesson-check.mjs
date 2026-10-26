// Stop hook: lessons that hold in every repo reach every repo (26 Oct 2026).
// 1. When Claude added a lesson to notes/lessons.md this turn outside the "## Shared" section, Claude is sent back
//    once to sort it: a lesson that holds in any repo goes under "## Shared (goes to every repo)", from where the
//    master copy collects it (scripts/collect-lessons.sh); in the master copy itself it goes straight into
//    .claude/rules/shared-lessons.md. A nudge: Claude decides, and stops without text when it is sorted.
// 2. When a lesson in that Shared section is already in .claude/rules/shared-lessons.md (it arrived with the sync),
//    Claude is sent back to delete it from notes/lessons.md, so it is not loaded twice.
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const root = process.env.CLAUDE_PROJECT_DIR || '.';
let conf = '';
try { conf = readFileSync(join(root, '.claude/ground-truth.conf'), 'utf8'); } catch {}
const confVar = (k, d) => (conf.match(new RegExp('^' + k + '="([^"]*)"', 'm')) || [])[1] || d;
const who = confVar('USER_NAME', 'the user');
const branch = confVar('WORK_BRANCH', 'the work branch');

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
if (input.stop_hook_active) process.exit(0);

const LESSONS = 'notes/lessons.md';
const SHARED = '.claude/rules/shared-lessons.md';
const SHARED_HEADING = /^##\s+Shared\b/i;
const isMaster = !existsSync(join(root, '.claude/workflow-version'));  // the master copy has no version file
const read = p => { try { return readFileSync(join(root, p), 'utf8'); } catch { return ''; } };
const norm = t => t.replace(/\s+/g, ' ').trim().toLowerCase();

// Bullets of a markdown text with the heading they are under: a bullet is a "- " line plus its indented lines.
function bullets(text) {
  const out = [];
  let heading = '', cur = null;
  for (const line of text.replace(/\r/g, '').split('\n')) {
    if (/^#{1,6}\s/.test(line)) { heading = line; cur = null; continue; }
    const m = line.match(/^\s*-\s+(.*)$/);
    if (m && !/^\s{2,}-/.test(line)) { cur = { heading, text: m[1] }; out.push(cur); continue; }
    if (cur && /^\s+\S/.test(line)) { cur.text += ' ' + line.trim(); continue; }
    cur = null;
  }
  return out.map(b => ({ heading: b.heading, key: norm(b.text), text: b.text }));
}
const short = t => (t.length > 90 ? t.slice(0, 87) + '...' : t);
const block = reason => { console.log(JSON.stringify({ decision: 'block', reason })); process.exit(0); };

const lessons = read(LESSONS);
const sharedKeys = new Set(bullets(read(SHARED)).map(b => b.key));

// 2. Shared lessons that already arrived with the sync.
const arrived = bullets(lessons).filter(b => SHARED_HEADING.test(b.heading) && sharedKeys.has(b.key));
if (!isMaster && arrived.length) {
  block('Lesson check: ' + arrived.length + ' lesson(s) under "## Shared" in ' + LESSONS + ' are already in ' + SHARED +
    ' (they arrived with the sync): ' + arrived.map(b => '"' + short(b.text) + '"').join('; ') +
    '. Delete them from ' + LESSONS + ' (keep the "## Shared (goes to every repo)" heading), then commit and push ' +
    'the docs to ' + branch + '.');
}

// 1. Lessons added this turn: sort them.
if (!input.transcript_path) process.exit(0);
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
let start = -1;
for (let i = entries.length - 1; i >= 0; i--) {
  const e = entries[i];
  if (e.type === 'user' && !e.isMeta && userText(e).trim() !== '') { start = i; break; }
}
if (start < 0) process.exit(0);

const added = new Set();
for (const e of entries.slice(start)) {
  if (e.type !== 'assistant') continue;
  for (const b of blocks(e)) {
    if (b.type !== 'tool_use' || !/notes[\\/]lessons\.md$/.test(b.input?.file_path || '')) continue;
    const edits = b.name === 'MultiEdit' ? (b.input.edits || []) : [b.input];
    for (const ed of edits) {
      const before = new Set(bullets(ed.old_string || '').map(x => x.key));
      for (const x of bullets(ed.new_string ?? ed.content ?? '')) if (!before.has(x.key)) added.add(x.key);
    }
  }
}
if (!added.size) process.exit(0);

const unsorted = bullets(lessons).filter(b => added.has(b.key) && !SHARED_HEADING.test(b.heading) && !sharedKeys.has(b.key));
if (!unsorted.length) process.exit(0);

const where = isMaster
  ? 'goes into ' + SHARED + ' (this is the master copy: the sync brings it to every repo) instead'
  : 'moves under "## Shared (goes to every repo)" at the end of ' + LESSONS + ' (add the heading if it is missing): ' +
    'the master copy collects it from there and the sync brings it to every repo';
block('Lesson check: you added ' + unsorted.length + ' lesson(s) to ' + LESSONS + ': ' +
  unsorted.map(b => '"' + short(b.text) + '"').join('; ') + '. A lesson that would hold in any repo (Claude Code, ' +
  'the PCs and tools, how Claude works with ' + who + ') ' + where + '. One only about this project stays where it is. ' +
  'If they are sorted, stop now and add no text.');
