# Claude Code session workflow

Automatic session start, a short handoff and a decision check for Claude Code, in every repo.
Started from github.com/truongfelix/workflow (6d2623c, 2026-10-10).

## Why every repo has its own copy, and why you never copy it

A cloud session (claude.ai/code, the phone app) reads only the repo's own `.claude/` folder. Settings in
`~/.claude` on a PC never reach it, and plugins do not load there. So every repo carries the files, and this repo is
the one place they are edited. A GitHub Action copies them: when a change reaches `main` here and the checks pass,
it opens (or updates) one "Workflow update" pull request in each repo of `sync/repos.txt`. Merging that pull request
is the whole update. Workflow to-dos are the issues of this repo.

## What it does

| File | When | What |
|---|---|---|
| `.claude/hooks/session-start.sh` | every session start | Cloud session: switches to `WORK_BRANCH` and pulls. PC: fast-forwards the checked-out branch when nothing is uncommitted or unpushed, otherwise says why not. Runs `ground-truth.sh`, checks whether the handoff is older than the last code commit, prints the handoff and the skills cheat sheet. Claude's first reply opens with the brief. |
| `cloud/setup-script.sh` | once, in the cloud environment | Pasted into the environment's Setup script (environment menu in the session's title bar, Edit, Setup script). A session with two or more repos opens in the folder that holds them, where no repo's hook runs; this installs a user-level hook that runs each repo's `session-start.sh` from there: one brief per repo, the skills list once. In a one-repo session it does nothing. |
| `.claude/hooks/handoff-check.sh` | after every reply | If pushed code on `WORK_BRANCH` is newer than the handoff, sends Claude back once to update and push it. |
| `.claude/hooks/decision-check.mjs` | after every reply | If the user answered a multiple-choice question or used decision words and no tracker changed (and no issue was opened), asks Claude to record the decision. |
| `.claude/hooks/issue-guard.mjs` | before every Bash or GitHub tool call | Blocks Claude from setting `Status: Ready` or `Status: Done`, from closing an issue, and from opening one outside `Status: Backlog`. `issue-guard.test.sh` next to it tests it (`bash .claude/hooks/issue-guard.test.sh`). |
| `.claude/hooks/branch-guard.mjs` | before every Bash or GitHub tool call | Blocks Claude from creating or pushing a branch named other than `WORK_BRANCH`, `WORK_BRANCH-<topic>` (1 to 4 lowercase words) or the sync's `workflow-sync`; a cloud session's own `claude/...` branch included. Deleting is never blocked. `branch-guard.test.sh` next to it tests it. |
| `.claude/rules/workflow.md` | every session (Claude Code loads it like CLAUDE.md) | The shared session and tracker rules, the same in every repo. A project's CLAUDE.md only adds to them. |
| `.claude/skills/CHEATSHEET.md` | every session start | One line per skill and hook: what it does, when to use it. The hook prints it and the brief ends with a short "Your skills" list, so they do not get forgotten. Update it with any skill change. |
| `.claude/skills/session-start/` | `/session-start`, and the hook | The brief, and `ground-truth.sh` (stale facts first, branches against GitHub, uncommitted work, open PRs and CI, open issues by status). `labels.sh` creates the issue labels. |
| `.claude/skills/handoff/` | `/handoff` | The full tidy-up at the end of a session. |
| `.claude/skills/crew/`, `.claude/agents/` | `/crew` | A feature round as a crew: this session plans, talks to the user, reviews and commits; a Haiku `scout` reads and a Sonnet `implementer` writes. Checks come from the repo's CLAUDE.md. Round records in `notes/crew/`. |
| `.claude/skills/grill-me/` | `/grill-me`, or before a big change | Interview in rounds, no cap on questions, each with a recommended answer ("yes" accepts it). |
| `.claude/skills/questionnaire/` | `/questionnaire` | Turns open questions (e.g. `questions.md` §1) into a document for one person to fill in; answers go back to the trackers. |
| `.claude/skills/wait-what/` | `/wait-what`, "I don't understand" | Re-explains the last message in plain words, with the missing context. |
| `.claude/skills/pr-body/` | writing a pull request | What changes, evidence, merge danger (one-way or two-way door, blast radius), how to test. |
| `.claude/skills/issue-run/` | a scheduled run | Unattended work on the issues: `check` asks the questions on the issues, `build` builds Ready issues and opens the pull request. |
| `.claude/skills/diagnosing-bugs/` | a bug or wrong number | Builds a check that fails on the bug first, then hypotheses, fix, proof, cleanup. |

The last five are adapted from github.com/mattpocock/skills (MIT, `.claude/skills/THIRD-PARTY.md`).

The scripts hold no project data. Everything project-specific is in `.claude/ground-truth.conf`.

Only in this master copy (not copied to the repos):

| File | When | What |
|---|---|---|
| `scripts/check.sh` | every pull request (`.github/workflows/check.yml`), and before a push | Every script parses, `settings.json` is valid and its hook files exist, the issue guard's tests pass, the cheat sheet lists every skill. |
| `.github/workflows/sync.yml`, `scripts/sync-all.sh` | every push to `main` that changes the workflow; by hand from the Actions tab | Runs `scripts/check.sh`, then opens or updates the "Workflow update" pull request in each repo of `sync/repos.txt`. |
| `scripts/sync.sh`, `scripts/sync-settings.mjs` | inside the sync; by hand to try a change | Brings one checkout up to this copy (README.md, "How the sync works"). |
| `sync/repos.txt` | read by the sync | The repos that get the workflow, one `owner/repo` per line. |
| `scripts/drift-check.sh` | Mondays 07:43 Budapest, scheduled task "Workflow drift check" | Compares each repo's `.claude/workflow-version` with `main` here and lists the workflow commits it is missing. The task opens or updates one Backlog issue here when a repo is behind. |

## How the sync works

**What is synced.** Every committed file under `.claude/` here, except `ground-truth.conf` and `settings.json`, which
are this repo's own. That covers the skills, the agents, the hooks, the cheat sheet and the shared rules
(`.claude/rules/workflow.md`, which Claude Code loads by itself, like CLAUDE.md). `.claude/workflow-manifest` in each
repo lists the synced files; a file removed here is removed there on the next sync.

**What stays the project's own.** The sync never touches these, so a project adds to the shared workflow here:

| File | Holds |
|---|---|
| `CLAUDE.md` | Only this project's rules: who, stack, checks, hard rules, extra "ask before". It adds to `.claude/rules/workflow.md` and never replaces it. |
| `.claude/ground-truth.conf` | This project's values (repos, work branch, handoff, user). When this copy's config gets a new key, the sync pull request says which key to add. |
| `.claude/settings.json` | The sync replaces only the hooks that run synced files and keeps every other key and hook. |
| `.claude/skills/<own name>/` and `.claude/skills/CHEATSHEET.project.md` | Skills only this project has, under a name not used here, with one line each in the project cheat sheet (the brief lists them). |
| `notes/`, `questions.md`, `BACKLOG.md` | The project's trackers. |

An edit to a synced file in a project repo does not last: the next sync pull request replaces it and its "Do before
merging" list names the file, so the project-specific part can move to that repo's CLAUDE.md.

**Where the pull request goes.** To the repo's work branch (`WORK_BRANCH` in its `ground-truth.conf`), where the
sessions run, from a branch named `workflow-sync`. There is one open sync pull request per repo at most: a newer
change updates it. The version reaches `main` with the next work branch to `main` merge, so until then the drift
check, which reads `main`, may still list the repo as behind.

**Latest or pinned.** Every repo follows the latest version through a pull request that the user merges (Balázs,
2026-10-23). Nothing merges by itself.

**The token.** The sync writes to repos of another owner (Kol-Lab-Design-Kft), so it needs a token in this repo's
secret `SYNC_TOKEN`:

1. GitHub, Settings, Developer settings, Fine-grained tokens, Generate new token.
2. Resource owner: Kol-Lab-Design-Kft. Repository access: only the repos in `sync/repos.txt`.
3. Permissions: Contents read and write, Pull requests read and write. Expiry: up to a year; note the date in
   `notes/lessons.md` with a `(check by YYYY-MM-DD)` tag a week before it.
4. This repo, Settings, Secrets and variables, Actions, New repository secret: name `SYNC_TOKEN`, the token as value.
5. Actions tab, "sync", Run workflow: one pull request per repo, or "already current".

A new repo added later needs to be added to the token's repository list too.

## Add it to a repo

1. Add `owner/repo` to `sync/repos.txt` (and to the token's repository list), merge to `main`. The sync opens the
   repo's first "Workflow update" pull request, with a template `ground-truth.conf` when the repo has none.
2. In that pull request's branch, fill in `.claude/ground-truth.conf`: `REPOS`, `WORK_BRANCH`, `HANDOFF`, `DOCS`,
   `USER_NAME`. Then merge it.
3. Create `notes/handoff.md`, `questions.md` (§1 open questions, §2 rulings), `notes/lessons.md` (with a
   `## Hook candidates` heading), `notes/crew/log.md` (its starting table is at the end of
   `.claude/skills/crew/SKILL.md`) and a `BACKLOG.md` that holds only the link to the repo's issues
   (`https://github.com/<owner>/<repo>/issues`).
4. Create the labels: `bash .claude/skills/session-start/labels.sh` (every GitHub repo in the config).
5. An existing `BACKLOG.md`: one issue per item, `Status: Backlog`, the section it sat in as its `Type:` label
   (pick the closest of feature, bug, config, docs) and the item's text as the body. Then cut the file down to the
   link. Every fact that can go stale, in `notes/lessons.md` or in a memory, gets a `(check by YYYY-MM-DD)` tag
   and lives in `notes/lessons.md` (delete the memory).
6. Write the repo's CLAUDE.md with this project's rules only; the shared ones come from `.claude/rules/workflow.md`.
7. Once per cloud environment (not per repo): paste `cloud/setup-script.sh` into its Setup script, so sessions
   with several repos get the brief too.
8. Check: start a new cloud session; the first reply must open with the brief, and the brief must list the issues
   by status. `bash .claude/hooks/issue-guard.test.sh` must print no FAIL.

Needs `bash`, `git` and `node` (cloud sessions have them; on Windows, Git Bash).

## Rules of this setup

Decided by Balázs on 2026-10-22, from an r/ClaudeCode post ("runs like a small engineering team"); GitHub stays, no
GitLab.

- Open work lives in GitHub issues. `BACKLOG.md` keeps only the link, so there is one list.
- `questions.md` stays a file: a ruling is a standing rule, not a task, and a closed issue drops out of sight.
- The check-by tag has one fixed form, `(check by YYYY-MM-DD)`, so the script can read it; other spellings are
  listed as BAD TAG.
- Facts that can go stale live only in `notes/lessons.md`: memories stay on one PC, and a cloud session cannot see
  their dates. Default 3 months, at most 12; a fact the user confirmed also expires, after 12 months.
- The user moves issues to Ready or Done by clicking on GitHub (website or phone app). The guard has no "unlock"
  phrase: a phrase could be copied from a document or an issue comment. Moving down (to Backlog or Blocked) needs
  no approval, so Claude may do it (Balázs, 22 Oct 2026): anything not in Ready is then the user's signal to look.
- Labels read as plain words, "Status: Ready", "Type: Bug" (Balázs, 22 Oct 2026; until then `status::ready`).
  `labels.sh` renames the old ones, so every issue keeps its status.
- Scheduled runs (Balázs, 22 Oct 2026): a day check every 4 hours asks its questions on the issues, a night build
  after midnight Budapest time builds the approved ones and opens the pull request; a phone notification only
  when something needs the user.
- Done = closed: the pull request says "Closes #<n>" and merging it is the approval. `Status: Done` is for work with
  no pull request (a server or a setting).
- Claude may open issues, always in backlog. An issue with a missing or double label is listed as NEEDS A LABEL,
  never guessed into a status.
- Issues are not shared outside the repo's collaborators for now (the repos are private).
- Decided by Balázs on 2026-10-23: this repo runs the workflow on itself (its own `CLAUDE.md`, handoff and
  trackers); `scripts/check.sh` runs on every pull request; every pull request gets `/code-review` before it opens
  and a watcher after; a weekly drift check (Mondays 07:43 Budapest, phone notification) reports repos on an old
  copy.
- Skills live only in the repos, never uploaded to a claude.ai account (Balázs, 2026-10-23): he works on a personal
  and a company account and does not want to install them on each, and only the repo copy reaches every session.
- Branches (Balázs, 2026-10-23): work goes on the work branch; a second branch only for parallel work, named
  `WORK_BRANCH-<topic>`, and the branch guard blocks any other name. No automatic branch deletion on GitHub: it
  would delete the work branch itself when its pull request is merged. A merged extra branch is deleted by hand
  ("Delete branch" on the pull request); a cloud session cannot delete branches (GitHub answers 403).
- Plugins stay out: plugins a repo's `.claude/settings.json` declares do not load in cloud sessions (Claude Code
  docs, "Settings in cloud sessions", checked 2026-10-23), so the files live in each repo.
- No hand copying (Balázs, 2026-10-23): a GitHub Action syncs the files to the repos as a pull request; each repo
  follows the latest version, merged by Balázs. The shared rules moved out of each CLAUDE.md into
  `.claude/rules/workflow.md`; a project's CLAUDE.md only adds to them. This repo stays on Balázs's personal account.
