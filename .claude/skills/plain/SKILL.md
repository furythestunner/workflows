---
name: plain
description: Explain a change, a pull request or a plan in plain words for someone who is not a developer, ready to paste into a pull request, a chat or an e-mail; or walk them through how an existing page or feature works, from their side. Use when the user says /plain, "what changed", "what does this pull request do", "explain it simply", "how does X work", "walk me through", "mi változott", "mit csinál ez", "magyarázd el egyszerűen", "hogyan működik", and for the "In plain words" section of every pull request (/pr-body).
metadata:
  short: "Explains a change, or how something works, in plain words."
---

# Plain words

Adapted from integralist/agent-skills (`summarize-for-product`, see `../THIRD-PARTY.md`).

Turn technical work into text a non-developer can act on. It is communication, not a record: write nothing to the
repo unless it goes into a pull request description.

1. **Know the source and the shape.** Take them from the request; ask only when it is unclear.
   - Source: a pull request, the work branch against `main` (`git diff origin/main...HEAD`, `git log
     origin/main..HEAD`; always `origin/main`, never a local `main`), an issue, a plan, or something that already
     exists (a page, a button, a number, an e-mail, a command).
   - Shape: `pr` (the "In plain words" section), `chat` (one short paragraph and 2 to 4 bullets), `email` (a
     subject line and 2 to 3 short paragraphs) or `walk` (how something that exists works, below).
2. **Read enough to be right.** A file list alone does not show what changed: read the diff and the code around it
   for every claim. Keep apart what is planned, built, tested and live. Done when every claim has evidence or is
   marked "not checked yet".
3. **Write it:**
   - What the reader sees or does: a page, a command, a GitHub screen, a file they open. No code names, no file
     paths unless the reader opens that file.
   - Short sentences, one idea each. Concrete numbers and times ("about 15 min", "3 repos").
   - What they need to do, if anything, as numbered steps. Say plainly when they need to do nothing.
   - The user's language. No em dashes.

   Done when the text is in the reply, inside a code block for easy copying (or in the pull request description).

**`pr`:**

```markdown
## In plain words
<1 to 2 sentences: what changes for whom>
- <what they will notice, one line each>
- <what they need to do, or "Nothing to do after the merge.">
```

**`chat`:** one paragraph with the point first, then 2 to 4 bullets, then a link to the pull request or issue.

**`walk`:** what happens, in the order the user meets it, from what they click to the result. One numbered step
per thing they do or see; under it, what happens out of sight that they would care about: who else sees it or gets
an e-mail, what is saved and where, where a number comes from (which entries it adds up), what blocks it (rights,
dates, a missing setting). End with the odd cases worth knowing (nothing there yet, a mistake, someone without the
right) and anything that surprised you in the code, marked as such. Read the code path end to end first; a step
you could not trace is marked "not checked".
