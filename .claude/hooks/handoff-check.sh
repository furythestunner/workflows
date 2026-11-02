#!/bin/bash
# Stop hook: keeps the handoff current without anyone typing /handoff (the user forgets it, and doing it later, on a
# cold cache, re-reads the whole conversation). After each reply, the first that applies sends Claude back once:
# 1. Context size: the conversation passed CONTEXT_WARN tokens (default 300000; a cloud session starts at about
#    77k), then every further 50k. Claude saves the handoff and tells the user to start a new session.
# 2. Pushed commits on WORK_BRANCH (code or docs; not the handoff or notes/rounds.md) newer than the handoff.
# 3. Talk: TALK_TURNS (4) messages from the user since the handoff was last committed, and nothing in 2. Asked once
#    per 4 messages; "nothing to hand off" is a valid answer (Claude stops without text).
# Unpushed commits are left alone (work in progress). What was already asked is kept in the git folder
# (handoff-check.state), never committed. Anything it cannot read is skipped.
input=$(cat)
case "$input" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
WORK_BRANCH="" HANDOFF="notes/handoff.md" USER_NAME="the user" CONTEXT_WARN=300000
[ -f .claude/ground-truth.conf ] && . .claude/ground-truth.conf
[ -n "$WORK_BRANCH" ] || exit 0
STEP=50000 TALK_TURNS=4
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
state=$(git rev-parse --git-path handoff-check.state)
ctx_tx="" ctx_level=0 talk_tx="" talk_n=0
[ -f "$state" ] && . "$state"
save() { printf 'ctx_tx=%q ctx_level=%q talk_tx=%q talk_n=%q\n' "$ctx_tx" "$ctx_level" "$talk_tx" "$talk_n" >"$state"; }
block() { local r=${1//\\/\\\\}; printf '{"decision":"block","reason":"%s"}\n' "${r//\"/\\\"}"; exit 0; }
on_branch=0; [ "$(git branch --show-current 2>/dev/null)" = "$WORK_BRANCH" ] && on_branch=1
h=$(git log -1 --format=%H -- "$HANDOFF" 2>/dev/null)
since=0; [ -n "$h" ] && since=$(git log -1 --format=%ct "$h")

# From the transcript: the context size of the last reply, and the user's messages after the handoff's commit.
tx="" tokens=0 turns=0
if command -v node >/dev/null; then
  read -r tokens turns tx < <(printf '%s' "$input" | SINCE=$since node -e '
    const fs = require("fs");
    let i; try { i = JSON.parse(fs.readFileSync(0, "utf8") || "{}"); } catch { process.exit(0); }
    const p = i.transcript_path; if (!p) process.exit(0);
    let es; try { es = fs.readFileSync(p, "utf8").split("\n").filter(Boolean).map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean); } catch { process.exit(0); }
    const typed = e => { const c = e.message?.content; return typeof c === "string" ? c.trim() !== "" :
      Array.isArray(c) && c.some(b => b.type === "image" || (b.type === "text" && b.text.trim())); };
    const since = Number(process.env.SINCE) * 1000;
    const turns = es.filter(e => e.type === "user" && !e.isMeta && !e.isSidechain && typed(e) && Date.parse(e.timestamp) > since).length;
    const last = [...es].reverse().find(e => e.type === "assistant" && !e.isSidechain && e.message?.usage);
    const u = last?.message.usage || {};
    const tokens = (u.input_tokens || 0) + (u.cache_read_input_tokens || 0) + (u.cache_creation_input_tokens || 0);
    console.log(tokens, turns, p);  // the path last: it may hold spaces' 2>/dev/null)
fi
tokens=${tokens:-0} turns=${turns:-0}
case "$tokens$turns" in *[!0-9]*) tokens=0 turns=0 ;; esac

# 1. Context size.
if [ -n "$tx" ]; then
  [ "$ctx_tx" = "$tx" ] || { ctx_tx=$tx ctx_level=0; }
  level=0; [ "$tokens" -ge "$CONTEXT_WARN" ] && level=$(( (tokens - CONTEXT_WARN) / STEP + 1 ))
  if [ "$level" -gt "$ctx_level" ]; then
    ctx_level=$level; save; k=$(( tokens / 1000 ))
    if [ "$on_branch" = 1 ] && [ "$(git rev-list --count '@{u}..HEAD' 2>/dev/null)" != "0" ]; then
      block "Context is at about ${k}k tokens: from here answers get less reliable and every reply re-reads all of it. $WORK_BRANCH has unpushed commits, so do not push half-done work: finish this step first (checks pass), then bring $HANDOFF up to date (Next, Waiting for $USER_NAME, Unfinished), commit and push it to $WORK_BRANCH. If the step cannot be finished now, tell $USER_NAME in one line what is unpushed and that a new session should start after it is pushed."
    elif [ "$on_branch" = 1 ]; then
      block "Context is at about ${k}k tokens: from here answers get less reliable and every reply re-reads all of it. Bring $HANDOFF up to date now: Next, Waiting for $USER_NAME, Unfinished (.claude/rules/workflow.md, Sessions and trackers); only what changed, and the date line. Commit and push it to $WORK_BRANCH (handoff rule: no need to ask). Then tell $USER_NAME in one line: the handoff is saved, the context is about ${k}k, start a new session for the next task."
    fi
    block "Context is at about ${k}k tokens: from here answers get less reliable and every reply re-reads all of it. This checkout is not on $WORK_BRANCH, so do not write the handoff here. Tell $USER_NAME in one line: the context is about ${k}k; finish this step, then type /handoff and start a new session."
  fi
  [ "$level" -lt "$ctx_level" ] && { ctx_level=$level; save; }  # after a compaction the reminders start again
fi

[ "$on_branch" = 1 ] && [ -n "$h" ] || exit 0
git rev-parse -q --verify '@{u}' >/dev/null 2>&1 || exit 0
[ "$(git rev-list --count '@{u}..HEAD')" = "0" ] || exit 0

# 2. Pushed commits newer than the handoff.
n=$(git rev-list --count --no-merges "$h"..HEAD -- . ":(exclude)$HANDOFF" ":(exclude)notes/rounds.md")
if [ "$n" -gt 0 ]; then
  block "Handoff is behind: $n pushed commit(s) on $WORK_BRANCH are newer than $HANDOFF. Before stopping, bring its three sections up to date (.claude/rules/workflow.md, Sessions and trackers): Next, Waiting for $USER_NAME, Unfinished; drop items that landed (their issues close when the pull request merges). If nothing in them changed, update only the date line. Then stage only those files (and notes/rounds.md if it changed), commit and push to $WORK_BRANCH (handoff rule: no need to ask). One line to $USER_NAME that the handoff was updated."
fi

# 3. Talk since the handoff.
if [ -n "$tx" ] && [ "$turns" -ge "$TALK_TURNS" ]; then
  [ "$talk_tx" = "$tx|$h" ] || { talk_tx="$tx|$h" talk_n=0; }  # a new handoff commit starts the count again
  if [ $(( turns - talk_n )) -ge "$TALK_TURNS" ]; then
    talk_n=$turns; save
    block "$turns messages from $USER_NAME since $HANDOFF was last committed. If this talk changed Next, Waiting for $USER_NAME or Unfinished (a plan for later, a step only $USER_NAME can do, with its full steps, work left half done), update only those lines and the date line, commit and push to $WORK_BRANCH (handoff rule: no need to ask), and say so in one line. Decisions go to their trackers, not here. If nothing there changed, stop without any text."
  fi
fi
exit 0
