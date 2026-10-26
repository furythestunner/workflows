// UserPromptSubmit hook: skills get forgotten, so every message is matched against a short phrase table and the
// fitting skill is named to Claude before it answers (26 Oct 2026, issue #20). A nudge, not a guarantee: Claude
// uses the skill unless it clearly does not fit. A message that starts with "/" (a skill typed) is left alone.
import { readFileSync } from 'node:fs';

const input = JSON.parse(readFileSync(0, 'utf8') || '{}');
const prompt = String(input.prompt || '');
if (!prompt.trim() || prompt.trimStart().startsWith('/')) process.exit(0);

// A review on a pull request arrives as a GitHub event: /verify is not optional there.
const REVIEW_EVENT = /<event[^>]*source="github"[^>]*kind="[^"]*(review|comment)[^"]*"/i;

// [skill, phrases, why]. English and Hungarian; keep each list short and specific.
const TABLE = [
  ['never-again', /\b(again|i (already )?(said|told you)|told you (before|already)|not what i (asked|said|meant)|stop doing|you forgot|keeps happening|never again)\b|már mondtam|megint|nem ezt kértem|elfelejtetted|soha többé/i,
    'this may be a correction. Check "Hook candidates" in notes/lessons.md: the first time, add one line there; if it is already listed, run /never-again and propose a hook'],
  ['plain', /\bwhat (has )?changed\b|\bwhat does (this|that|the) (pr|pull request|change|commit) do\b|\b(explain|say) it (simply|plainly)\b|\bin plain words\b|mi változott|mit csinál (ez|a)|magyarázd el egyszerűen/i,
    'the user wants a change explained in plain words'],
  ['distill', /\btoo long\b|\bshorten\b|\bmake it shorter\b|\bcondense\b|túl hosszú|rövidíts|rövidebb/i,
    'the user wants a text shorter without losing anything'],
  ['wait-what', /\bwait,? what\b|\bi don'?t (understand|get it)\b|\bwhat does (that|this) mean\b|nem értem|ez mit jelent/i,
    'the last message did not land'],
  ['grill-me', /\bgrill me\b|\bask me everything\b|kérdezz ki/i,
    'the user wants to be interviewed about a plan'],
  ['diagnosing-bugs', /\b(broken|doesn'?t work|not working|stopped working|bug|wrong (number|total|result)s?|too slow|crash(es|ed)?)\b|nem működik|elromlott|hibás|lassú/i,
    'something is broken, wrong or slow'],
  ['questionnaire', /\bquestionnaire\b|\bquestions for (the )?(client|owner|him|her|them)\b|kérdőív/i,
    'questions only someone else can answer'],
  ['pr-body', /\b(how risky|safe to merge|merge danger)\b|mennyire veszélyes|biztonságos.{0,20}merge/i,
    'the user asks how risky a merge is'],
  ['handoff', /\b(wrap up|end of (the )?day|done for today|switching machines|battery (is )?dying)\b|mára ennyi|befejezzük|gépet váltok/i,
    'the user is finishing the session'],
  ['session-start', /\bwhere are we\b|\bwhat'?s next\b|\bwhere did we (leave|stop)\b|hol tartunk|mi a következő/i,
    'the user asks where things stand'],
];

const lines = [];
if (REVIEW_EVENT.test(prompt)) {
  lines.push('- /verify: a review arrived on a pull request. Follow .claude/skills/verify/SKILL.md before changing ' +
    'code or replying: check each comment against the code, then fix it or answer with a reason.');
} else {
  for (const [skill, re, why] of TABLE) if (re.test(prompt)) lines.push(`- /${skill}: ${why}.`);
}
if (!lines.length) process.exit(0);

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    additionalContext: 'Skill nudge (.claude/hooks/skill-nudge.mjs): this message fits\n' + lines.slice(0, 2).join('\n') +
      '\nUse the skill (read its SKILL.md) unless it clearly does not fit; then say in one line which skill you used.',
  },
}));
