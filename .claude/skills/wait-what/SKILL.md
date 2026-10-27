---
name: wait-what
description: Re-explain the last message that did not land, simpler and with the missing context. Use when the user says /wait-what, "wait what", "I don't understand", "what does that mean", "nem értem", "ez mit jelent", or answers a question in a way that shows the explanation was missed.
metadata:
  short: "Re-explains the last answer, simpler and with context."
---

# Wait, what?

Adapted from mattpocock/skills (`wait-what`, MIT, see `../THIRD-PARTY.md`).

The last message did not land. Re-pitch it; do not repeat it.

1. **Start one step back:** one or two sentences on where we are and why this came up.
2. **Say it again in plain words:** what the user sees or does on the site or in the tool, not code, file names or
   database terms. Short sentences, one idea each (Simplified Technical English). If a technical word is unavoidable,
   explain it in a few words.
3. **Say what it means for the user:** what changes, what they need to do (if anything), what happens if they don't.
4. **If there was a question,** ask it again in one line, with your recommendation.

Answer in the user's language. Keep it shorter than the message that failed. When the earlier message was wrong
rather than unclear, say so plainly and correct it.
