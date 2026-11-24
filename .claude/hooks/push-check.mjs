// PreToolUse hook: two checks before a git push.
// 1. The repo's own checks pass before a push, not only in CI afterwards (26 Oct 2026). Runs CHECK from
//    .claude/ground-truth.conf (for example CHECK="bash scripts/check.sh") in the project root and blocks the push
//    when it fails, with the failing lines. No CHECK, no check. A check that runs longer than 100 seconds is let
//    through, so a slow one never blocks for good.
// 2. No work behind a merged pull request (23 Nov 2026; it happened twice in the intranet, #9 and #138). A push to
//    WORK_BRANCH is blocked when the branch's newest pull request is merged, no pull request from it is open, and
//    the push carries new work: files outside DOCS, in commits that are neither in that pull request nor in its base.
//    Docs alone (the handoff after a merge) ride along to the next pull request. The way through: push and open the
//    new pull request in the same command (git push ... && gh pr create ...). It asks GitHub through `gh api` (REST,
//    which cloud sessions allow); without gh, or offline, it lets the push through: a guard against mistakes.
//    (PUSH_CHECK_GH names a stand-in for gh, a node script: the tests use it.)
// Deleting a branch is not checked.
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
if (input.tool_name !== 'Bash') process.exit(0);
const root = resolve(process.env.CLAUDE_PROJECT_DIR || input.cwd || '.');
const command = String(input.tool_input?.command ?? '');

// The pushes in this command: "git push" after "cd x &&" or as "git -C x push". Deleting a branch is skipped.
// Each push keeps its words and what came before it in the same folder (git add, git commit), and whether a
// gh pr create follows it.
const pushes = []; let cwd = root; const before = new Map();
for (const seg of command.split(/&&|\|\||[;|\n]/)) {
  const words = (seg.match(/"[^"]*"|'[^']*'|\S+/g) || []).map(w => w.replace(/^(["'])(.*)\1$/, '$2'));
  if (words[0] === 'cd' && words[1]) { cwd = resolve(cwd, words[1]); continue; }
  if (/(^|\s|\()gh\s+pr\s+create\b/.test(seg)) { pushes.forEach(p => { p.prAfter = true; }); continue; }
  if (words[0] !== 'git') continue;
  let i = 1, dir = cwd;
  if (words[1] === '-C' && words[2]) { dir = resolve(cwd, words[2]); i = 3; }
  if (words[i] === 'push') {
    const args = words.slice(i + 1);
    if (!args.some(w => w === '--delete' || w === '-d' || w.startsWith(':'))) pushes.push({ dir, args, before: before.get(dir) || [] });
  } else if (words[i] === 'add' || words[i] === 'commit') {
    before.set(dir, [...(before.get(dir) || []), words.slice(i)]);
  }
}
const dirs = new Set(pushes.map(p => p.dir));

const conf = dir => { try { return readFileSync(join(dir, '.claude/ground-truth.conf'), 'utf8'); } catch { return ''; } };
const val = (text, key) => (text.match(new RegExp(`^${key}="([^"]*)"`, 'm')) || [])[1];
const git = (dir, args) => {
  // core.quotePath=false: accented file names (Iván.md) come out as they are, not quoted.
  const r = spawnSync('git', ['-C', dir, '-c', 'core.quotePath=false', ...args], { encoding: 'utf8', timeout: 10000 });
  return r.status === 0 ? r.stdout : null;
};
const lines = s => (s || '').split('\n').map(l => l.trimEnd()).filter(Boolean);

// Check 2, for one push: the reason to block it, or nothing.
function mergedPr(p) {
  const text = conf(p.dir);
  const work = val(text, 'WORK_BRANCH');
  if (!work || p.prAfter) return '';
  // git push [options] [remote [refspec...]]: the remote and the refspecs aimed at the work branch.
  const pos = []; const a = p.args;
  for (let k = 0; k < a.length; k++) {
    if (a[k] === '-o' || a[k] === '--push-option' || a[k] === '--repo') { k++; continue; }
    if (a[k] === '--all' || a[k] === '--mirror' || a[k] === '--tags') return '';
    if (!a[k].startsWith('-')) pos.push(a[k]);
  }
  const remote = pos[0] || 'origin';
  const current = lines(git(p.dir, ['rev-parse', '--abbrev-ref', 'HEAD']))[0] || '';
  const specs = pos.length > 1 ? pos.slice(1) : [current];
  const srcs = specs.map(s => s.replace(/^\+/, '')).map(s => {
    const [src, dst = src] = s.split(':');
    const to = (dst === 'HEAD' ? current : dst).replace(/^refs\/heads\//, '');
    return to === work ? (src || 'HEAD') : null;
  }).filter(Boolean);
  if (!srcs.length) return '';

  // The GitHub repo: the REPOS entry for this folder, else the remote's address.
  let slug = '';
  for (const m of text.matchAll(/"([^"|]*)\|([^"|]*)\|[^"|]*\|[^"|]*\|([^"|]*)"/g)) {
    if (m[3] && resolve(root, m[2]) === resolve(p.dir)) slug = m[3];
  }
  if (!slug) slug = (lines(git(p.dir, ['remote', 'get-url', remote]))[0] || '')
    .match(/github\.com[:/]([^/]+\/[^/]+?)(?:\.git)?\/?$/)?.[1] || '';
  if (!slug) return '';

  // The pull requests from the work branch, newest first. Any trouble: let the push through.
  const [cmd, pre] = process.env.PUSH_CHECK_GH ? ['node', [process.env.PUSH_CHECK_GH]] : ['gh', []];
  const owner = slug.split('/')[0];
  const r = spawnSync(cmd, [...pre, 'api', `repos/${slug}/pulls?state=all&head=${owner}:${work}&per_page=20`],
    { cwd: p.dir, encoding: 'utf8', timeout: 10000 });
  let prs;
  try { prs = r.status === 0 ? JSON.parse(r.stdout) : null; } catch { prs = null; }
  if (!Array.isArray(prs) || !prs.length) return '';
  if (prs.some(pr => pr.state === 'open')) return '';
  const last = prs.reduce((x, y) => (y.number > x.number ? y : x));
  if (!last.merged_at) return '';

  // The new work: files of commits in the push that are in neither the merged pull request nor its base.
  const base = last.base?.ref || 'main';
  const not = [last.head?.sha, `${remote}/${base}`].filter(ref => ref && git(p.dir, ['rev-parse', '--verify', '-q', `${ref}^{commit}`]) !== null);
  const files = new Set();
  for (const src of srcs) {
    const out = git(p.dir, ['log', '--format=', '--name-only', src, ...not.map(r => `^${r}`)]);
    if (out === null) return '';
    lines(out).forEach(f => files.add(f));
  }
  // A commit in the same command is not made yet: count what it will take (staged files, git add's paths, -A, -a, -u).
  const add = out => lines(out).forEach(f => files.add(f));
  if (p.before.some(step => step[0] === 'commit')) {
    add(git(p.dir, ['diff', '--cached', '--name-only']));
    for (const step of p.before) {
      const rest = step.slice(1);
      if (rest.some(w => w === '-A' || w === '--all') || (step[0] === 'add' && rest.includes('.')))
        for (let f = (git(p.dir, ['status', '--porcelain', '-z', '-uall']) || '').split('\0'), k = 0; k < f.length; k++) {
          if (f[k].length > 3) files.add(f[k].slice(3));
          if (/^[RC]/.test(f[k])) k++; // a rename or copy: the old name follows as its own field
        }
      else if (rest.some(w => w === '-u' || w === '--update' || (step[0] === 'commit' && /^-[a-zA-Z]*a/.test(w))))
        add(git(p.dir, ['diff', '--name-only', 'HEAD']));
      if (step[0] === 'add') rest.filter(w => !w.startsWith('-') && w !== '.').forEach(w => files.add(w.replace(/^\.\//, '')));
    }
  }
  const docs = (val(text, 'DOCS') || '').split(/\s+/).filter(Boolean).map(d => d.replace(/\/$/, ''));
  const isDoc = f => docs.some(d => f === d || f.startsWith(d + '/'));
  const newWork = [...files].map(f => f.replace(/\/$/, '')).filter(f => f && !isDoc(f));
  if (!newWork.length) return '';
  return `Pull request #${last.number} from ${work} is already merged, and no pull request from ${work} is open. ` +
    `This push carries new work (${newWork.slice(0, 5).join(', ')}${newWork.length > 5 ? ', ...' : ''}): pushed alone, ` +
    `it would sit behind the merged pull request, and nobody would see it. Push and open a new pull request for ` +
    `this work in the same command (git push ... && gh pr create ..., after /code-review). Or first check that ` +
    `this work belongs on ${work} at all.`;
}

const blocked = [];
for (const p of pushes) { const why = mergedPr(p); if (why) blocked.push(why); }
if (blocked.length) {
  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: 'Push check: ' + blocked.join('\n'),
    },
  }));
  process.exit(0);
}

// Check 1: the repo's own checks.
const failed = [];
for (const dir of dirs) {
  const check = val(conf(dir), 'CHECK');
  if (!check) continue;
  const r = spawnSync('bash', ['-c', check], { cwd: dir, encoding: 'utf8', timeout: 100000, maxBuffer: 64 << 20 });
  if (r.error || r.status === 0 || r.status === null) continue;
  const out = `${r.stdout || ''}\n${r.stderr || ''}`.split('\n').filter(Boolean);
  const fails = out.filter(l => /\bFAIL|error|Error/.test(l));
  failed.push(`\`${check}\` in ${dir} failed (exit ${r.status}):\n` + (fails.length ? fails : out).slice(-15).join('\n'));
}
if (!failed.length) process.exit(0);

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'PreToolUse',
    permissionDecision: 'deny',
    permissionDecisionReason: 'Push check: this push would turn CI red. Fix it first, then push again.\n' + failed.join('\n'),
  },
}));
