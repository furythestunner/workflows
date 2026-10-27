// PreToolUse hook: synced files are edited only in the master copy (26 Oct 2026). In a project repo, a file listed
// in .claude/workflow-manifest comes from github.com/furythestunner/workflows, and the next sync undoes any edit made
// here. Blocks Edit, Write, MultiEdit and NotebookEdit on those files. The master copy (no .claude/workflow-version)
// and the sync's own branch (workflow-sync) are not checked. A guard against mistakes: a shell edit is not inspected.
import { readFileSync, existsSync } from 'node:fs';
import { join, resolve, dirname, relative, sep } from 'node:path';
import { execFileSync } from 'node:child_process';

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
const args = input.tool_input || {};
const file = args.file_path || args.notebook_path;
if (!file) process.exit(0);
const abs = resolve(process.env.CLAUDE_PROJECT_DIR || input.cwd || '.', file);

// The repo the file is in: the nearest folder up from it with a .claude/workflow-manifest (a session can hold several).
let root = dirname(abs);
while (!existsSync(join(root, '.claude/workflow-manifest'))) {
  const up = dirname(root);
  if (up === root) process.exit(0);
  root = up;
}
if (!existsSync(join(root, '.claude/workflow-version'))) process.exit(0);

let branch = '';
try {
  branch = execFileSync('git', ['branch', '--show-current'], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
} catch {}
if (branch === 'workflow-sync') process.exit(0);

const rel = relative(root, abs).split(sep).join('/');
let synced;
try {
  synced = new Set(readFileSync(join(root, '.claude/workflow-manifest'), 'utf8').replace(/\r/g, '').split('\n')
    .filter(l => l && !l.startsWith('#')));
} catch { process.exit(0); }
if (!synced.has(rel)) process.exit(0);

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'PreToolUse',
    permissionDecision: 'deny',
    permissionDecisionReason: `Synced-file guard: ${rel} comes from the workflow master copy ` +
      '(.claude/workflow-manifest), and the next sync undoes any edit made here. Make the change in ' +
      'github.com/furythestunner/workflows (a workflow to-do is an issue there); put what is specific to this ' +
      'project in CLAUDE.md, .claude/ground-truth.conf or a project skill (.claude/skills/CHEATSHEET.project.md).',
  },
}));
