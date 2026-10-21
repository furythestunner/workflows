---
name: questionnaire
description: Turn open questions only someone else can answer into a short document for that one person to fill in, async or together in a meeting. Use when the user says /questionnaire, "make a questionnaire", "kérdőív", or wants to send questions from questions.md §1 to someone (an owner, a client, a colleague).
---

# Questionnaire

Adapted from mattpocock/skills (`to-questionnaire`, MIT, see `../THIRD-PARTY.md`).

The recipient knows something the user does not. The questionnaire pulls it out of them in one pass.

**Ask the user about the send, not the subject.** They can always answer who it goes to and what they need back;
the questions in the document then target the gap between the two.

## Steps

1. **Who is it for?** The recipient's role, what they know that the user does not, and their language (write the
   document in it). Skip what is already clear from the chat or the trackers. Done when you can say in one line who
   reads it and what they know.
2. **What do you need back?** The decisions or facts the user needs. When the user names `questions.md` §1, take
   those entries (with their options and recommendations) as the list and show it for a quick OK. Done when there is
   a concrete list of what the user must be able to decide afterwards.
3. **Write it** to `notes/questionnaires/<yyyy-mm-dd>-<topic>.md` with the template below and give the user the
   path. Done when every item from step 2 has a question.
4. **When the answers come back** (the user pastes them or the file is filled in): move each answered question in
   `questions.md` §1 to §2 as 🟢 with the recipient's words and the date, put new work in `BACKLOG.md`, and say
   what is still unanswered.

## Writing the questions

- Plain words, about what people see and do, never code or database terms. The recipient was not in the chat.
- Most important first: an async reader may stop after the first few.
- One idea per question, never two joined by "and". A short answer space under each.
- Where there are options, list them as (a), (b), (c), with what each one means for the recipient in practice,
  and the recommendation if the user wants to share it.
- A one-line "Why this matters" only where the question could be misread or invite a throwaway answer.
- Group under `##` headings by theme once there are more than five questions.

## Template

```markdown
# <Title>

**Purpose:** <why this exists and the decision that depends on it>
**From:** <user> · **To:** <recipient> · **Answers by:** <date, if any> · **Effort:** <about N minutes>

## Context
<One short paragraph: enough to answer well, not a page.>

## How to answer
Write under each question. "I don't know" and partial answers help too; mark what you are unsure of.

## <Theme>

### 1. <Question>
_Why this matters: ..._ (only when needed)

(a) ... (b) ...

> 

## Anything else?
Anything we did not ask that we should know?
```
