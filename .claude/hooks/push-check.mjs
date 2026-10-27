// PreToolUse hook: the repo's own checks pass before a push, not only in CI afterwards (26 Oct 2026). Before a
// git push, runs CHECK from .claude/ground-truth.conf (for example CHECK="bash scripts/check.sh") in the project
// root and blocks the push when it fails, with the failing lines. No CHECK, no check. Deleting a branch is not
// checked. A check that runs longer than 100 seconds is let through, so a slow one never blocks for good.
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
if (input.tool_name !== 'Bash') process.exit(0);
const root = resolve(process.env.CLAUDE_PROJECT_DIR || input.cwd || '.');

// The repos this command pushes from: "git push" after "cd x &&" or as "git -C x push". Deleting a branch is skipped.
const dirs = new Set(); let cwd = root;
for (const seg of String(input.tool_input?.command ?? '').split(/&&|\|\||[;|\n]/)) {
  const words = (seg.match(/"[^"]*"|'[^']*'|\S+/g) || []).map(w => w.replace(/^(["'])(.*)\1$/, '$2'));
  if (words[0] === 'cd' && words[1]) { cwd = resolve(cwd, words[1]); continue; }
  if (words[0] !== 'git') continue;
  let i = 1, dir = cwd;
  if (words[1] === '-C' && words[2]) { dir = resolve(cwd, words[2]); i = 3; }
  if (words[i] === 'push' && !words.slice(i + 1).some(w => w === '--delete' || w === '-d' || w.startsWith(':'))) dirs.add(dir);
}

const failed = [];
for (const dir of dirs) {
  let conf = '';
  try { conf = readFileSync(join(dir, '.claude/ground-truth.conf'), 'utf8'); } catch {}
  const check = (conf.match(/^CHECK="([^"]*)"/m) || [])[1];
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
