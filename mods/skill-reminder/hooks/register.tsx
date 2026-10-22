import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { SkillId } from '../types'

const PANE = 'skill-reminder'
const TITLE = 'Skills & tools'

type Entry = {
  id: string
  name: string
  kind: 'skill' | 'hook'
  summary: string
  // Words in a prompt that mean this skill would help.
  cues?: RegExp
}

const ENTRIES: Entry[] = [
  {
    id: 'session-start',
    name: '/session-start',
    kind: 'skill',
    summary:
      'Brief on where things stand: branches, open PRs and CI, the handoff, and a proposed task of the day. Runs by itself at session start; type it after /clear or when you ask "where are we?".',
    cues: /where (are|were) we|what'?s next|resume|continue the work|start the day/i,
  },
  {
    id: 'handoff',
    name: '/handoff',
    kind: 'skill',
    summary:
      'End-of-session tidy-up: writes notes/handoff.md and the trackers, then commits and pushes. Use before closing, switching machines or /clear, so the next session starts from zero context.',
    cues: /\b(wrap up|end of (the )?day|done for (the )?day|switching machines|battery|hand ?off|finish(ing)? up)\b/i,
  },
  {
    id: 'grill-me',
    name: '/grill-me',
    kind: 'skill',
    summary:
      'Claude interviews you in rounds about a plan until every open question is settled, each with a recommended answer ("yes" accepts it). Use before a big change where a wrong guess means rework.',
    cues: /\b(plan|design|architecture|refactor|migrat\w*|rewrite|new feature)\b/i,
  },
  {
    id: 'questionnaire',
    name: '/questionnaire',
    kind: 'skill',
    summary:
      'Turns open questions only someone else can answer (questions.md §1) into a short document for that person to fill in. Use when you are blocked on a client, owner or colleague.',
    cues: /\b(ask (the )?(client|owner|boss|team)|need to ask|waiting on|kérdőív)\b/i,
  },
  {
    id: 'wait-what',
    name: '/wait-what',
    kind: 'skill',
    summary:
      'Re-explains Claude\'s last message in plain words with the missing context. Use whenever an answer did not land.',
    cues: /\b(wait,? what|i don'?t understand|what does that mean|confus\w*|nem értem)\b/i,
  },
  {
    id: 'pr-body',
    name: '/pr-body',
    kind: 'skill',
    summary:
      'The shape for a pull request description: what changes for users, evidence it works, and merge danger. Use when opening or updating a PR, or asking how risky a merge is.',
    cues: /\b(pull request|open a pr|create a pr|pr description|merge risk)\b/i,
  },
  {
    id: 'diagnosing-bugs',
    name: '/diagnosing-bugs',
    kind: 'skill',
    summary:
      'A disciplined bug loop: first a check that fails on the bug, then hypotheses, fix and proof. Use for anything broken, wrong, slow, or when a quick fix did not work.',
    cues: /\b(bug|broken|crash\w*|error|fails?|failing|wrong (number|result)|slow|debug)\b/i,
  },
  {
    id: 'hook-session-start',
    name: 'session-start hook',
    kind: 'hook',
    summary:
      'Automatic at every session start: moves a cloud session to the work branch, runs ground-truth.sh and loads the handoff, so the first reply opens with the brief. Nothing to type.',
  },
  {
    id: 'hook-handoff-check',
    name: 'handoff-check hook',
    kind: 'hook',
    summary:
      'Automatic after every reply: if pushed code is newer than notes/handoff.md, Claude is sent back once to update and push it.',
  },
  {
    id: 'hook-decision-check',
    name: 'decision-check hook',
    kind: 'hook',
    summary:
      'Automatic after every reply: when you answered a question or made a decision and no tracker changed, Claude is asked to record it in questions.md, BACKLOG.md or CLAUDE.md.',
  },
]

const nudged = atom({ plugin: 'skill-reminder', key: 'nudged' } as const, [] as SkillId[])

const nudge = async ($: EngineInterface, text: string) => {
  const already = await read($, nudged)
  const hit = ENTRIES.find(
    one =>
      one.cues !== undefined &&
      !already.includes(one.id) &&
      !text.includes(one.name) &&
      one.cues.test(text),
  )

  if (hit !== undefined) {
    await update($, nudged, list => [...list, hit.id])
    $.ui.toast(`Tip: ${hit.name} fits this. ${hit.summary.split('. ')[0]}.`)
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'my-skills',
      description: 'Show the repo skills and hooks, with what each is for',
    })
    void $.ui.open({ id: PANE, title: TITLE })

    return next(e)
  })

  on('command.run', { command: 'my-skills' }, async $ => {
    await $.ui.open({ id: PANE, title: TITLE })

    return { text: 'Skills pane opened.' }
  })

  // The reminder: when a prompt reads like a job a skill does, say so once per session.
  on('prompt.submit', async ($, e, next) => {
    // A failed nudge must never hold up the prompt.
    await nudge($, e.text).catch(() => undefined)

    return next(e)
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)

    const section = (kind: Entry['kind'], heading: string) => (
      <Box flexDirection="column" marginBottom={1}>
        <Text bold>{heading}</Text>
        {ENTRIES.filter(one => one.kind === kind).map(one => (
          <Box flexDirection="column" marginBottom={1}>
            <Text color="cyan">{one.name}</Text>
            <Text dimColor>{one.summary}</Text>
          </Box>
        ))}
      </Box>
    )

    return (
      <Box flexDirection="column">
        {section('skill', 'Skills: type the /command')}
        {section('hook', 'Hooks: run by themselves')}
      </Box>
    )
  })
}
