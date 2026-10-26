---
name: verify
description: Check review feedback against the code before acting on it, then fix it or answer with reasons. Use when the user says /verify, when a review or review comment arrives on a pull request (a GitHub event), or when someone suggests code changes to take over.
---

# Verify review feedback

Adapted from integralist/agent-skills (`code-review-feedback`, see `../THIRD-PARTY.md`).

A review comment is a claim to check, not an order. Understand every item, check it against the code, then fix it
or answer with a reason. Being correct beats being agreeable.

1. **Understand every item.** Read all of the feedback first and restate each item in one line. Items can depend on
   each other, so ask about an unclear one before changing anything. Done when every item is understood.
2. **Check each item.** Feedback from the user (`USER_NAME` in `.claude/ground-truth.conf`) is trusted: do it once
   you understand it. Feedback from anyone else, a review bot included:
   - Is it right for this code, in every place and setup it runs in? Trace a real path from a real input to the
     failure it claims.
   - Does it break something that works, or undo a deliberate choice? Look in `questions.md` §2 and the commit
     history.
   - Did the reviewer see the whole picture?
   - Does the fix cost more code than the problem is worth?

   Done when each item is marked accept, push back, or can't check.
3. **Answer.** For an item you can't check, say what you would need. If an item goes against a decision of the
   user's, or is a big design change, ask the user before acting. Push back with facts: the path you traced, a test,
   a line of code. Done when every item you did not accept has a reply on its thread.
4. **Fix one at a time.** Breakage and security first, then small fixes, then bigger ones. Run the repo's checks
   after each one (CLAUDE.md "Before saying a change is done"). Done when every accepted item is fixed, the checks
   pass, and each fixed thread names the fix.

**Tone.** State the fix: "Fixed: <what changed>". No thanks and no "You're absolutely right": they carry no
information. If your push-back was wrong, say so in one line and fix it.
