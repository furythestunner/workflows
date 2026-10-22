export type SkillId = string

declare module 'claude-code' {
  interface PluginState {
    'skill-reminder': { nudged: SkillId[] }
  }
}
