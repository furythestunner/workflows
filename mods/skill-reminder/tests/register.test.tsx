import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'skill-reminder',
  component: 'Pane',
  requestId: 'skill-reminder',
  props: {
    title: 'Skills & tools',
    isFocused: false,
    bodyColumns: 40,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 40 },
    view: {},
  },
} as const

test('the pane lists every skill and hook with its summary, on every surface', async ($, on) => {
  on('command.register', () => ({ value: { command: 'my-skills' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))

  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  for (const surface of ['terminal', 'desktop', 'vscode', 'mobile'] as const) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect((await ui.find({ type: 'Text', text: /^\/grill-me$/ }))?.text).toBe('/grill-me')
    expect((await ui.find({ type: 'Text', text: /^handoff-check hook$/ }))?.text).toBe('handoff-check hook')
    expect((await ui.find({ type: 'Text', text: /hypotheses, fix and proof/ }))?.text).toContain('bug loop')
    await ui.unmount()
  }
})
