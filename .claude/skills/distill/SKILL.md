---
name: distill
description: Shorten a long text without losing anything needed to act on it, checked item by item. Use when the user says /distill, "too long", "shorten this", "make it shorter", "túl hosszú", "rövidítsd", or when scripts/check.sh warns that a rules file, a CLAUDE.md or a SKILL.md is too long.
---

# Distill

Adapted from integralist/agent-skills (`distill`, see `../THIRD-PARTY.md`).

Rewrite a text shorter and clearer without losing anything a reader needs. Keeping the content is the goal;
shortness is the means. Any shortening can silently drop a path, an order of steps or an exception, and in a rules
file a dropped line becomes a wrong action. So list what must survive, rewrite, then check the rewrite against the
list. The check is the point.

**Target.** Pasted text: give the rewrite in the chat, write nothing. A file: read all of it, show the change with
the check, and write it only once the user approves. A synced file (`.claude/workflow-manifest`) is changed only in
the master copy.

1. **List** every item that must survive, as a checklist. When two items contradict each other, keep the one that
   wins and note the other as dropped. Done when the whole text is read and the list written.
2. **Rewrite** in short, direct sentences; lists, tables and steps are fine. Copy paths, commands, names and values
   exactly. Add no fact the text did not have. If the text is already tight, say so and change little. Done when
   the rewrite is drafted.
3. **Check** each list item against the rewrite. Put back anything lost by accident, and tell the user about any
   cut that is risky instead of making it silently. Done when every item has an outcome.

**Keep / cut.** When unsure, keep it: a spare sentence costs little, a lost rule costs a wrong action.

| Keep | Cut |
|---|---|
| Exact paths, commands, values | Filler, hedging, warm-up sentences |
| Order of steps, what must come first | Repetition, restated context |
| Exceptions, warnings, edge cases | Story-telling, history no one acts on |
| When a step is done | Explaining the obvious |
| A reason that prevents a wrong action | Apologies, motivation |

**Output.** The rewrite, then the check, one line per item:

```txt
- <item>: kept | moved to <where> | cut: <reason>
```

For a long or important text, hand step 3 to a fresh `scout` agent with only the list and the rewrite (not your
reasoning), and ask it to report any item it cannot find.
