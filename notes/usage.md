# Usage

Written by `.claude/hooks/run.mjs`: how often each hook fired (blocked a call, sent Claude back or added a
note) and each skill was used, counted from the first day in its row. A row that stays low is a candidate to
cut; a hook or skill with no row never fired. Do not edit by hand.

| What | Times | First | Last |
|---|---|---|---|
| `branch-guard` | 1 | 2026-11-19 | 2026-11-19 |
| `decision-check` | 6 | 2026-11-22 | 2026-11-27 |
| `fact-check` | 2 | 2026-11-22 | 2026-11-22 |
| `handoff-check` | 4 | 2026-11-10 | 2026-11-27 |
| `push-check` | 1 | 2026-11-27 | 2026-11-27 |
| `review-guard` | 2 | 2026-11-10 | 2026-11-27 |
| `skill anthropic-skills:computer-use` | 1 | 2026-11-22 | 2026-11-22 |
| `skill code-review` | 6 | 2026-11-10 | 2026-11-27 |
