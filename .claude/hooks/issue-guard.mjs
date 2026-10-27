// PreToolUse hook: only the user approves work (22 Oct 2026). Claude may not move an issue to "Status: Ready" or
// "Status: Done", may not close an issue, and opens new issues only in "Status: Backlog". Moving an issue back to
// Backlog or to Blocked is allowed. Closing is allowed when the user's own last typed message says to close that
// issue by number, with or without # ("close #12", "close 12", "zárd le a #12-t") (26 Oct 2026); issue comments and tool output never count. The old label names ("status::ready") are matched too. Covers the GitHub tools
// (mcp__*github*) and gh / curl in Bash. A guard against mistakes, not against someone set on getting round it:
// a payload read from a file (--input) is not inspected.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

let conf = '';
try { conf = readFileSync(join(process.env.CLAUDE_PROJECT_DIR || '.', '.claude/ground-truth.conf'), 'utf8'); } catch {}
const who = (conf.match(/^USER_NAME="([^"]*)"/m) || [])[1] || 'the user';

let input;
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { process.exit(0); }
const tool = input.tool_name || '';

// The user's last typed message: a human turn in the transcript, without pasted blocks. Empty when unreadable.
function lastUserText() {
  let lines;
  try { lines = readFileSync(input.transcript_path, 'utf8').split('\n'); } catch { return ''; }
  for (let i = lines.length - 1; i >= 0; i--) {
    let e;
    try { e = JSON.parse(lines[i]); } catch { continue; }
    if (e.type !== 'user' || e.isMeta || (e.origin && e.origin.kind !== 'human')) continue;
    const c = e.message?.content;
    const text = typeof c === 'string' ? c
      : Array.isArray(c) ? c.filter(b => b.type === 'text').map(b => b.text).join('\n') : '';
    if (text.trim()) return text.replace(/<pasted_content\b[\s\S]*?<\/pasted_content>/g, '');
  }
  return '';
}
// "close #12", "close 12", "close issues #12 and #14", "zárd le a 12-t"; never a sentence with a "no" in it ("don't close #12").
function closeAsked(nums) {
  nums = [].concat(nums).filter(Boolean);
  if (!nums.length) return false;
  const yes = lastUserText().split(/[.\n!?;]/).filter(s =>
    /\b(close|closing)\b|zár/i.test(s) && !/\b(don'?t|do not|not|never|ne|nem)\b|n't\b/i.test(s));
  return nums.every(n => yes.some(s => new RegExp(String.raw`(?<!\d)#?${n}(?!\d)`).test(s)));
}
// Every issue a command closes: "gh issue close 12 && gh issue close 13", ".../issues/12 ... state=closed".
const issueNos = s => [...String(s).matchAll(/(?:issues\/|issue\s+close\s+#?)(\d+)/g)].map(m => m[1]);
const args = input.tool_input || {};

// "Status: Ready", "status::ready" and their URL forms ("Status%3A%20Ready", "status%3A%3Aready").
const SEP = String.raw`(?:::|:|%3A%3A|%3A)(?:\s|%20|\+)*`;
const APPROVED = new RegExp(String.raw`status${SEP}(ready|done)\b`, 'i');
const BACKLOG = new RegExp(String.raw`status${SEP}backlog\b`, 'i');
// A command counts only where a command starts (line start, after ; & | ( or $( ), so that text that merely
// mentions one, such as a commit message, passes.
const run = re => new RegExp(String.raw`(^|[;&|(\n]|\$\()\s*` + re.source);

function check() {
  if (/^mcp__.*github/i.test(tool)) {
    if (/__(list|get|search)_|_read$/i.test(tool)) return null; // reading, e.g. listing the ready issues
    const labels = [].concat(args.labels ?? []).map(String);
    if (labels.some(l => APPROVED.test(l))) return 'set "Status: Ready" or "Status: Done"';
    if (/label/i.test(tool) && ['name', 'new_name'].some(k => APPROVED.test(String(args[k] ?? ''))))
      return 'change the "Status: Ready" or "Status: Done" label';
    if (/issue/i.test(tool)) {
      if ((String(args.state ?? '').toLowerCase() === 'closed' || /^close/i.test(String(args.method ?? ''))) &&
          !closeAsked(args.issue_number))
        return 'close an issue';
      if (String(args.method ?? '').toLowerCase() === 'create' && !labels.some(l => BACKLOG.test(l)))
        return 'open an issue outside "Status: Backlog" (add the labels "Status: Backlog" and one "Type:" label)';
    }
    return null;
  }
  if (tool !== 'Bash') return null;
  const cmd = String(args.command ?? '');
  if (run(/gh\s+issue\s+delete\b/).test(cmd)) return 'delete an issue';
  if (run(/gh\s+issue\s+close\b/).test(cmd) && !closeAsked(issueNos(cmd))) return 'close an issue';
  if (run(/gh\s+issue\s+(edit|create)\b/).test(cmd)) {
    const added = [...cmd.matchAll(/(?:--add-label|--label|-l)[=\s]+("[^"]*"|'[^']*'|\S+)/g)].map(m => m[1]);
    if (added.some(l => APPROVED.test(l))) return 'set "Status: Ready" or "Status: Done"';
    if (run(/gh\s+issue\s+create\b/).test(cmd) && !added.some(l => BACKLOG.test(l)))
      return 'open an issue outside "Status: Backlog" (add --label "Status: Backlog" and one "Type:" label)';
  }
  if (run(/gh\s+label\s+(edit|delete)\b/).test(cmd) && APPROVED.test(cmd))
    return 'change the "Status: Ready" or "Status: Done" label';
  if (run(/(gh\s+api|curl)\b/).test(cmd)) {
    const method = (cmd.match(/(?:-X|--method|--request)[=\s]+["']?([A-Za-z]+)/) || [])[1]?.toUpperCase() ||
      (/\s(-f|-F|--field|--raw-field|--input|-d|--data\S*)[=\s]/.test(cmd) ? 'POST' : 'GET');
    if (method === 'GET') return null;
    // Taking a label off an issue (Ready -> In progress) is allowed; deleting or renaming the label itself is not.
    if (method === 'DELETE') return APPROVED.test(cmd) && !/issues\/\d+\/labels\//.test(cmd)
      ? 'delete the "Status: Ready" or "Status: Done" label' : null;
    if (APPROVED.test(cmd)) return 'set "Status: Ready" or "Status: Done"';
    if (/state["']?\s*[=:]\s*["']?closed/i.test(cmd) && !closeAsked(issueNos(cmd))) return 'close an issue';
  }
  return null;
}

const what = check();
if (what) {
  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: 'Issue guard: Claude may not ' + what + '. Only ' + who + ' moves issues to Ready or ' +
        'Done, on GitHub (website or phone app). Claude closes an issue only when ' + who + '\'s own last message ' +
        'says to close it by number ("close #12"); otherwise give ' + who + ' the link to the issue and say what to click. Claude may move Ready -> In progress, any -> Blocked (with the ' +
        'question posted on the issue), any -> Backlog (on hold) and In progress -> Review (with an open pull request ' +
        'that says "Closes #<n>", or "Part of #<n>" in building mode).'
    }
  }));
}
