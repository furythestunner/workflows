// Runs one workflow hook (every hook in .claude/settings.json goes through here):
//   node .claude/hooks/run.mjs <hook file in .claude/hooks> | --skill | --fold
// 1. The off switch: when the file .claude/workflow-off exists, no hook runs (the session start says so in one
//    line). The user creates that file, on GitHub, when a hook update breaks the sessions; deleting it turns the hooks
//    back on. Claude may not create it: it would switch off every guard.
// 2. The usage record: a hook that fires (blocks a call, sends Claude back or adds a note) and every skill that
//    is used gets one line in the git folder (workflow-usage.log, never committed). --fold adds those lines to the
//    counts in notes/usage.md, which goes into the next handoff commit (.claude/hooks/handoff-check.sh, /handoff).
//    So "is this hook or skill ever used?" has a count, not a guess.
// A hook's output and exit code pass through unchanged. Anything the runner itself cannot do is skipped.
import { readFileSync, existsSync, appendFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = process.env.CLAUDE_PROJECT_DIR || join(here, '..', '..');
const OFF = '.claude/workflow-off';
const name = process.argv[2] || '';

const logPath = () => {
  const r = spawnSync('git', ['-C', root, 'rev-parse', '--git-path', 'workflow-usage.log'], { encoding: 'utf8' });
  const p = (r.stdout || '').trim();
  return r.status === 0 && p ? (/^([A-Za-z]:|\/)/.test(p) ? p : join(root, p)) : '';
};
const record = what => {
  try { const p = logPath(); if (p) appendFileSync(p, new Date().toISOString().slice(0, 10) + '\t' + what + '\n'); } catch {}
};

// --fold: the log's lines go into the table of notes/usage.md (next to the handoff), then the log is emptied.
if (name === '--fold') {
  try {
    const p = logPath();
    const lines = p && existsSync(p) ? readFileSync(p, 'utf8').split('\n').filter(Boolean) : [];
    if (!lines.length) process.exit(0);
    let conf = '';
    try { conf = readFileSync(join(root, '.claude/ground-truth.conf'), 'utf8'); } catch {}
    const handoff = (conf.match(/^HANDOFF="([^"]*)"/m) || [])[1] || 'notes/handoff.md';
    const file = join(root, dirname(handoff), 'usage.md');
    const rows = new Map(); // what -> [count, first day, last day]
    if (existsSync(file)) {
      for (const l of readFileSync(file, 'utf8').split('\n')) {
        const m = l.match(/^\| `([^`]+)` \| (\d+) \| (\d{4}-\d\d-\d\d) \| (\d{4}-\d\d-\d\d) \|$/);
        if (m) rows.set(m[1], [Number(m[2]), m[3], m[4]]);
      }
    }
    for (const l of lines) {
      const [day, what] = l.split('\t');
      if (!what || !/^\d{4}-\d\d-\d\d$/.test(day)) continue;
      const r = rows.get(what) || [0, day, day];
      rows.set(what, [r[0] + 1, r[1] < day ? r[1] : day, r[2] > day ? r[2] : day]);
    }
    const out = ['# Usage', '',
      'Written by `.claude/hooks/run.mjs`: how often each hook fired (blocked a call, sent Claude back or added a',
      'note) and each skill was used, counted from the first day in its row. A row that stays low is a candidate to',
      'cut; a hook or skill with no row never fired. Do not edit by hand.', '',
      '| What | Times | First | Last |', '|---|---|---|---|',
      ...[...rows.entries()].sort((a, b) => a[0].localeCompare(b[0]))
        .map(([w, [n, first, last]]) => `| \`${w}\` | ${n} | ${first} | ${last} |`), ''];
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, out.join('\n'));
    writeFileSync(p, '');
  } catch {}
  process.exit(0);
}

let raw = '';
try { raw = readFileSync(0, 'utf8'); } catch {}
let input = {};
try { input = JSON.parse(raw || '{}'); } catch {}

if (existsSync(join(root, OFF))) {
  if (name === 'session-start.sh')
    console.log('WORKFLOW OFF: the file ' + OFF + ' exists, so no workflow hook runs in this repo (no brief, no ' +
      'guards, no handoff check). Say this first in your reply. To turn the hooks back on, the user deletes that ' +
      'file on GitHub and starts a new session.');
  process.exit(0);
}

// Claude may not create the off switch (a guard against mistakes, like the other guards).
const args = input.tool_input || {};
const target = String(args.file_path ?? args.path ?? '').replace(/\\/g, '/');
const cmd = input.tool_name === 'Bash' ? String(args.command ?? '') : '';
if (/(^|\/)\.claude\/workflow-off$/.test(target) && /^(Write|Edit|MultiEdit|mcp__)/.test(input.tool_name || '') ||
    /(^|[;&|(\n]|\$\()\s*(touch|tee|cp|mv|ln|install|echo|printf|:)\b[^;&|\n]*\.claude\/workflow-off\b/.test(cmd) ||
    />\s*["']?[^;&|\s]*\.claude\/workflow-off\b/.test(cmd)) {
  console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: 'deny',
    permissionDecisionReason: 'Off switch: only the user creates ' + OFF + ', on GitHub (it turns off every ' +
      'workflow hook in this repo). Tell the user what is broken and write out the steps: on GitHub open ' +
      'this repo, pick the work branch, Add file, Create new file, name it ' + OFF + ', Commit changes; then start ' +
      'a new session.' } }));
  process.exit(0);
}

// Skills used: a typed /name, or the Skill tool.
const typed = String(input.prompt || '').match(/^\s*\/([a-z][\w:-]*)/i);
if (typed) record('skill ' + typed[1]);
if (input.tool_name === 'Skill' && args.skill) record('skill ' + String(args.skill));
if (name === '--skill' || !name) process.exit(0);

const file = join(here, name);
if (!/^[\w.-]+$/.test(name) || !existsSync(file)) process.exit(0);
const r = spawnSync(name.endsWith('.sh') ? 'bash' : process.execPath, [file], {
  input: raw, encoding: 'utf8', env: { ...process.env, CLAUDE_PROJECT_DIR: root }, maxBuffer: 16 * 1024 * 1024,
});
if (r.stdout) process.stdout.write(r.stdout);
if (r.stderr) process.stderr.write(r.stderr);
const status = r.status ?? 0;
// The session start always prints; every other hook prints (or exits 2) only when it fires.
if (name !== 'session-start.sh' && (status === 2 || (r.stdout || '').trim())) record(name.replace(/\.(mjs|sh)$/, ''));
process.exit(status);
