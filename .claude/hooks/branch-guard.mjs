// PreToolUse hook: no randomly named branches (23 Oct 2026). Work goes on the work branch (WORK_BRANCH in the repo's
// .claude/ground-truth.conf). A second branch, when parallel work needs one, is named "<work branch>-<topic>", the
// topic 1 to 4 lowercase words joined by hyphens. The sync's own "workflow-sync" is the only other name. Checks the
// git commands that create or push a branch (checkout -b, switch -c, branch, worktree add -b, push) and the GitHub
// tools' create_branch. Deleting a branch is never blocked. A repo without WORK_BRANCH is not checked. A guard
// against mistakes, not against someone set on getting round it; anything it cannot read is let through.
import { readFileSync, existsSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { execFileSync } from 'node:child_process';

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
const tool = input.tool_name || '';
const args = input.tool_input || {};
const projectDir = process.env.CLAUDE_PROJECT_DIR || input.cwd || '.';

const readConf = (dir) => { try { return readFileSync(join(dir, '.claude/ground-truth.conf'), 'utf8'); } catch { return ''; } };
const confValue = (conf, key) => (conf.match(new RegExp(`^${key}="([^"]*)"`, 'm')) || [])[1] || '';

const SYNC_BRANCH = 'workflow-sync';
const okName = (name, wb) => name === wb || name === SYNC_BRANCH ||
  (name.startsWith(wb + '-') && /^[a-z0-9]+(-[a-z0-9]+){0,3}$/.test(name.slice(wb.length + 1)));

// Splits a command line into simple commands (on && || ; | and newlines), each a list of words, keeping quoted
// text together, so that "git push" inside a commit message is not taken for a command.
function commands(line) {
  const out = []; let words = []; let word = null; let q = null;
  const endWord = () => { if (word !== null) words.push(word); word = null; };
  const endCmd = () => { endWord(); if (words.length) out.push(words); words = []; };
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (q) { if (c === q) q = null; else if (c === '\\' && q === '"' && i + 1 < line.length) word += line[++i]; else word += c; continue; }
    if (c === "'" || c === '"') { q = c; word = word ?? ''; }
    else if (c === '\\' && i + 1 < line.length) word = (word ?? '') + line[++i];
    else if (c === '&' || c === '|' || c === ';' || c === '\n' || c === '(' || c === ')') endCmd();
    else if (c === ' ' || c === '\t') endWord();
    else word = (word ?? '') + c;
  }
  endCmd();
  return out;
}

function git(dir, ...a) {
  try { return execFileSync('git', ['-C', dir, ...a], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim(); }
  catch { return ''; }
}

// The branch names a git command creates or pushes to (empty when it does neither), and the folder it runs in.
function gitTargets(w, cwd) {
  let i = 1;
  while (i < w.length && w[i].startsWith('-')) { // global options: -C <dir>, -c <key=value>
    if (w[i] === '-C') cwd = resolve(cwd, w[++i] || '.');
    else if (w[i] === '-c') i++;
    i++;
  }
  const sub = w[i]; const rest = w.slice(i + 1);
  const pos = rest.filter(a => !a.startsWith('-'));
  const has = (...f) => rest.some(a => f.includes(a));
  const after = (...f) => { const k = rest.findIndex(a => f.includes(a)); return k >= 0 ? rest[k + 1] : undefined; };
  let names = [];
  if (sub === 'checkout') names = [after('-b', '-B')];
  else if (sub === 'switch') names = [after('-c', '-C', '--create', '--force-create')];
  else if (sub === 'worktree' && rest[0] === 'add') names = [after('-b', '-B')];
  else if (sub === 'branch') {
    if (has('-m', '-M', '--move', '-c', '-C', '--copy')) names = [pos[pos.length - 1]];
    else if (!has('-d', '-D', '--delete', '-l', '--list', '-a', '--all', '-r', '--remotes', '-v', '-vv', '--show-current',
      '--contains', '--merged', '--no-merged', '-u', '--set-upstream-to', '--unset-upstream', '--edit-description'))
      names = [pos[0]];
  } else if (sub === 'push') {
    if (has('-d', '--delete', '--all', '--tags', '--mirror')) return { names: [], cwd };
    const p = []; // positionals, skipping the values of options that take one
    for (let k = 0; k < rest.length; k++) {
      if (['--repo', '-o', '--push-option', '--receive-pack', '--exec'].includes(rest[k])) { k++; continue; }
      if (!rest[k].startsWith('-')) p.push(rest[k]);
    }
    const specs = p.slice(1);
    if (!specs.length) names = [git(cwd, 'rev-parse', '--abbrev-ref', 'HEAD')];
    else names = specs.map(s => {
      s = s.replace(/^\+/, '');
      if (s.startsWith(':')) return ''; // ":name" deletes
      if (!s.includes(':') && git(cwd, 'rev-parse', '--verify', '-q', 'refs/tags/' + s)) return ''; // a tag
      let dst = s.includes(':') ? s.split(':')[1] : s;
      if (dst === 'HEAD') dst = git(cwd, 'rev-parse', '--abbrev-ref', 'HEAD');
      if (dst.startsWith('refs/') && !dst.startsWith('refs/heads/')) return ''; // tags, notes
      return dst.replace(/^refs\/heads\//, '');
    });
  }
  return { names: names.filter(n => n && n !== 'HEAD'), cwd };
}

// The work branch of the GitHub repo owner/name: from a ground-truth.conf here, inside or next to the project.
function workBranchOf(owner, repo) {
  const id = `${owner}/${repo}`.toLowerCase();
  for (const dir of [projectDir, join(projectDir, repo), join(dirname(projectDir), repo)]) {
    const conf = readConf(dir);
    if (conf && conf.toLowerCase().includes(id)) return confValue(conf, 'WORK_BRANCH');
  }
  return '';
}

function check() {
  if (/^mcp__.*github.*__create_branch$/i.test(tool)) {
    const wb = workBranchOf(String(args.owner || ''), String(args.repo || ''));
    const name = String(args.branch || '');
    return wb && name && !okName(name, wb) ? { name, wb } : null;
  }
  if (tool !== 'Bash') return null;
  let cwd = input.cwd || projectDir;
  for (const w of commands(String(args.command ?? ''))) {
    if (w[0] === 'cd' && w[1]) { cwd = resolve(cwd, w[1]); continue; }
    if (w[0] !== 'git') continue;
    const t = gitTargets(w, cwd);
    if (!t.names.length) continue;
    const top = git(t.cwd, 'rev-parse', '--show-toplevel');
    const wb = top && existsSync(top) ? confValue(readConf(top), 'WORK_BRANCH') : '';
    if (!wb) continue;
    const bad = t.names.find(n => !okName(n, wb));
    if (bad) return { name: bad, wb };
  }
  return null;
}

const hit = check();
if (hit) {
  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: `Branch guard: "${hit.name}" is not an allowed branch name here. Work on the work ` +
        `branch "${hit.wb}" (a cloud session's own claude/... branch is never pushed). Only when parallel work really ` +
        `needs a second branch, name it "${hit.wb}-<topic>", the topic 1 to 4 lowercase words joined by hyphens ` +
        `(e.g. "${hit.wb}-leave-totals"). The sync's own "${SYNC_BRANCH}" is the only other name.`
    }
  }));
}
