// PreToolUse hook: no passwords, tokens or keys in a commit (26 Oct 2026). Before git commit or git push, and before
// the GitHub tools write files, looks at what would go out: file names like .env or *.pem, and added lines that look
// like a token (GitHub, Anthropic, AWS, Slack) or a private key. Blocks and names the file, never the secret.
// A guard against mistakes, not a scanner: anything it cannot read is let through.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { execFileSync } from 'node:child_process';

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
const tool = input.tool_name || '';
const args = input.tool_input || {};
const root = resolve(process.env.CLAUDE_PROJECT_DIR || input.cwd || '.');

const BAD_NAME = /(^|\/)(\.env(\.(?!example$|sample$|template$)[^/]+)?|id_(rsa|dsa|ecdsa|ed25519)|[^/]+\.(pem|key|pfx|p12)|credentials\.json|secrets?\.(json|ya?ml))$/i;
const TOKENS = [
  ['a GitHub token', /\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}\b|\bgithub_pat_[A-Za-z0-9_]{50,}/],
  ['an Anthropic API key', /\bsk-ant-[A-Za-z0-9_-]{20,}/],
  ['an AWS access key', /\bAKIA[0-9A-Z]{16}\b/],
  ['a Slack token', /\bxox[abprs]-[A-Za-z0-9-]{10,}/],
  ['a private key', /-----BEGIN (RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----/],
];

const found = [];
function look(path, added) {
  if (BAD_NAME.test(path)) found.push(`${path} (a secrets file by its name)`);
  for (const [what, re] of TOKENS) if (re.test(added)) { found.push(`${path} (${what})`); break; }
}
const git = (dir, ...a) => {
  try { return execFileSync('git', ['-C', dir, '-c', 'core.quotePath=false', ...a], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], maxBuffer: 64 << 20 }); }
  catch { return ''; }
};
// Splits a unified diff into files with their added lines. A deleted file (+++ /dev/null) adds nothing.
function lookDiff(diff) {
  for (const part of diff.split(/^diff --git /m).slice(1)) {
    const path = (part.match(/^\+\+\+ "?b\/(.+?)"?$/m) || [])[1];
    if (!path) continue;
    look(path, part.split('\n').filter(l => l.startsWith('+') && !l.startsWith('+++')).join('\n'));
  }
}
// A file as it would be added: text only, at most 1 MB read.
function lookFile(dir, path) {
  let text = '';
  try { text = readFileSync(resolve(dir, path)).subarray(0, 1 << 20).toString('utf8'); } catch {}
  look(path, text.includes('\0') ? '' : text);
}
// The git commands in a command line, each with the folder it runs in (after "cd x &&" or "git -C x").
function gitCommands(cmd) {
  const out = []; let cwd = root;
  for (const seg of cmd.split(/&&|\|\||[;|\n]/)) {
    const words = (seg.match(/"[^"]*"|'[^']*'|\S+/g) || []).map(w => w.replace(/^(["'])(.*)\1$/, '$2'));
    if (words[0] === 'cd' && words[1]) { cwd = resolve(cwd, words[1]); continue; }
    if (words[0] !== 'git') continue;
    let i = 1, dir = cwd;
    if (words[1] === '-C' && words[2]) { dir = resolve(cwd, words[2]); i = 3; }
    out.push({ dir, sub: words[i], args: words.slice(i + 1) });
  }
  return out;
}

if (/^mcp__.*github/i.test(tool)) {
  if (/push_files$/i.test(tool)) for (const f of [].concat(args.files ?? [])) look(String(f.path ?? ''), String(f.content ?? ''));
  else if (/create_or_update_file$/i.test(tool)) look(String(args.path ?? ''), String(args.content ?? ''));
} else if (tool === 'Bash') {
  for (const { dir, sub, args: a } of gitCommands(String(args.command ?? ''))) {
    // git add: only the paths this add would stage (a dry run), not every loose file.
    if (sub === 'add') for (const m of git(dir, 'add', '--dry-run', ...a).matchAll(/^add '(.+)'$/gm)) lookFile(dir, m[1]);
    if (sub === 'commit') {
      lookDiff(git(dir, 'diff', '--cached'));
      if (a.some(x => /^-(-all|[a-zA-Z]*a[a-zA-Z]*)$/.test(x))) lookDiff(git(dir, 'diff'));
    }
    if (sub === 'push') {
      // What the push sends: since the upstream, or for a new branch since the remote's default branch.
      const base = ['@{u}', 'origin/HEAD', 'origin/main'].find(r => git(dir, 'rev-parse', '--verify', '-q', r).trim());
      if (base) lookDiff(git(dir, 'diff', `${base}...HEAD`));
    }
  }
}
if (!found.length) process.exit(0);

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'PreToolUse',
    permissionDecision: 'deny',
    permissionDecisionReason: 'Secret guard: this would put what looks like a secret on GitHub: ' +
      [...new Set(found)].join('; ') + '. Take it out (unstage it, add the file to .gitignore, keep the value in ' +
      'the environment\'s secrets) and say so to the user. If it is not a secret (a test value, an example), ' +
      'tell the user and ask before going on.',
  },
}));
