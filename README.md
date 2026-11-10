# Claude Code session workflow

Automatic session start, a short handoff and a decision check for Claude Code, in every repo.
Started from github.com/truongfelix/workflow (6d2623c, 2026-10-10).

## Why every repo has its own copy, and why you never copy it

A cloud session (claude.ai/code, the phone app) reads only the repo's own `.claude/` folder. Settings in
`~/.claude` on a PC never reach it, and plugins do not load there. So every repo carries the files, and this repo is
the one place they are edited. A GitHub Action copies them: when a change reaches `main` here and the checks pass,
it opens (or updates) one "Workflow update" pull request in each repo of `sync/repos.txt`. The sync merges it by itself
unless it needs a step by hand (its "Do before merging" list). Workflow to-dos are the issues of this repo.

## What it does

| File | When | What |
|---|---|---|
| `.claude/hooks/run.mjs` | around every hook | The runner: every hook in `.claude/settings.json` starts through it. It holds the off switch (the file `.claude/workflow-off` stops every hook; "When a workflow update breaks the sessions" below) and the usage record (each hook that fires and each skill used is counted into `notes/usage.md`). `run.test.sh` tests it. |
| `.claude/hooks/session-start.sh` | every session start | Cloud session: switches to `WORK_BRANCH` and pulls. PC: fast-forwards the checked-out branch when nothing is uncommitted or unpushed, otherwise says why not. Runs `ground-truth.sh`, checks whether the handoff is older than the last code commit, prints the handoff (and a project's own skills list, when it has one). Claude's first reply opens with the brief. |
| `cloud/setup-script.sh` | once, in the cloud environment | Pasted into the environment's Setup script (environment menu in the session's title bar, Edit, Setup script). A session with two or more repos opens in the folder that holds them, where no repo's hook runs; this installs a user-level hook that runs each repo's `session-start.sh` from there: one brief per repo. In a one-repo session it does nothing. |
| `.claude/hooks/handoff-check.sh` | after every reply | Keeps the handoff current while the cache is warm, so nobody has to type `/handoff`. Sends Claude back once to update and push it when: the conversation passes `CONTEXT_WARN` tokens (default 300000; a cloud session starts at about 77k) and again every further 50k, and then Claude tells the user to start a new session; pushed commits on `WORK_BRANCH` (code or docs) are newer than the handoff; 4 of the user's messages came after the handoff's last commit (asked once per 4; Claude stops without text when nothing changed). Unpushed work is left alone. What it already asked is kept in `.git/handoff-check.state`. Before it sends Claude back it adds the session's hook and skill counts to `notes/usage.md`, which goes into the same commit. `handoff-check.test.sh` tests it. |
| `.claude/hooks/decision-check.mjs` | after every reply | If the user answered a multiple-choice question or used decision words and no tracker changed (and no issue was opened), asks Claude to record the decision. `README.md` and `.claude/rules/` count as trackers; plain "decision" or "szabály" in a sentence does not count as deciding. `decision-check.test.sh` tests it. |
| `.claude/hooks/lesson-check.mjs` | after every reply | If Claude added a lesson to `notes/lessons.md` this turn outside its "## Shared" section, sends Claude back once to sort it (only this project, or shared). If a lesson in that section already arrived in `.claude/rules/shared-lessons.md`, has Claude delete the copy. `lesson-check.test.sh` next to it tests it. |
| `.claude/rules/shared-lessons.md` | every session (loaded by itself, like the rules) | Everyday lessons that hold in every repo, collected from the repos (README, "Shared lessons"). Edited only here. |
| `.claude/lessons/shared-facts.md` | when the topic comes up | Narrow facts that hold in every repo (one tool, one PC, one limit). Not loaded by itself: the shared lessons name its topics, and Claude reads it then. Its check-by dates are in the brief like the others. |
| `.claude/hooks/issue-guard.mjs` | before every Bash or GitHub tool call | Blocks Claude from setting `Status: Ready`, from closing an issue, and from opening one outside `Status: Backlog`. `issue-guard.test.sh` next to it tests it (`bash .claude/hooks/issue-guard.test.sh`). |
| `.claude/hooks/branch-guard.mjs` | before every Bash or GitHub tool call | Blocks Claude from creating or pushing a branch named other than `WORK_BRANCH`, `WORK_BRANCH-<topic>` (1 to 4 lowercase words) or the sync's `workflow-sync`; a cloud session's own `claude/...` branch included. Deleting is never blocked. `branch-guard.test.sh` next to it tests it. |
| `.claude/hooks/push-check.mjs` | before every `git push` | Runs `CHECK` from `.claude/ground-truth.conf` (here `bash scripts/check.sh`, about 15 s) and blocks the push when it fails, with the failing lines. No `CHECK`, no check; the sync never asks for it. `push-check.test.sh` tests it. |
| `.claude/hooks/secret-guard.mjs` | before every `git commit`, `git push` and GitHub file write | Blocks when what would go out has a secrets file (`.env`, `*.pem`, `*.key`, `credentials.json`, ...) or a line that looks like a GitHub, Anthropic, AWS or Slack token or a private key. Names the file, never the secret. `secret-guard.test.sh` tests it. |
| `.claude/hooks/review-guard.mjs` | before opening a pull request | Blocks until `/code-review` has run in the session (Claude called it or the user typed it). `review-guard.test.sh` tests it. |
| `.claude/hooks/synced-guard.mjs` | before every Edit or Write | In a project repo, blocks edits to a file listed in `.claude/workflow-manifest` (the next sync would undo them), except on the sync's `workflow-sync` branch. Does nothing here. `synced-guard.test.sh` tests it. |
| `.claude/hooks/fact-check.mjs` | after every reply | If the reply says the repo has or lacks something ("already has", "there is no") and Claude opened no file that turn, sends Claude back once to check the file, cite it and correct a wrong claim. `fact-check.test.sh` tests it. |
| `.claude/hooks/dash-check.mjs` | every message the user sends | If CLAUDE.md says "no em dashes" and Claude's previous reply had one, reminds Claude before it answers. No extra turn. `dash-check.test.sh` tests it. |
| `.claude/rules/workflow.md` | every session (Claude Code loads it like CLAUDE.md) | The shared session and tracker rules, the same in every repo. A project's CLAUDE.md only adds to them. |
| `.claude/skills/CHEATSHEET.md` | when you want the list | One line per skill and hook: what it does, when to use it. For the user; no hook prints it (Claude Code lists the skills for Claude by itself). Update it with any skill change. |
| `.claude/skills/session-start/` | `/session-start`, and the hook | The brief, and `ground-truth.sh` (stale facts first, branches against GitHub, uncommitted work, open PRs and CI, open issues by status). `labels.sh` creates the issue labels and moves issues out of the statuses that were dropped. `ground-truth.test.sh` tests the script and the session start hook on a scratch repo. |
| `.claude/skills/handoff/` | `/handoff` | The full tidy-up at the end of a session. |
| `.claude/skills/crew/`, `.claude/agents/` | `/crew` | A feature round as a crew: this session plans, talks to the user, reviews and commits; a Haiku `scout` reads, a Sonnet `implementer` writes and a Sonnet `reviewer` checks the diff against the brief. `fence.sh` stops a round whose change touches a file the brief does not list. The user gets a smoke list of only the steps no check could cover. Checks come from the repo's CLAUDE.md. Round records in `notes/crew/`. |
| `.claude/skills/grill-me/` | `/grill-me`, or before a big change | Interview in rounds, no cap on questions, each with a recommended answer ("yes" accepts it). |
| `.claude/skills/questionnaire/` | `/questionnaire` | Turns open questions (e.g. `questions.md` §1) into a document for one person to fill in; answers go back to the trackers. |
| `.claude/skills/wait-what/` | `/wait-what`, "I don't understand" | Re-explains the last message in plain words, with the missing context. |
| `.claude/skills/pr-body/` | writing a pull request | What changes, evidence, merge danger (one-way or two-way door, blast radius), how to test. |
| `.claude/skills/issue-run/` | a scheduled run | Unattended work on the issues: `check` asks the questions on the issues, `build` builds Ready issues and opens the pull request. |
| `.claude/skills/diagnosing-bugs/` | a bug or wrong number | Builds a check that fails on the bug first, then hypotheses, fix, proof, cleanup. |
| `.claude/skills/never-again/` | `/never-again`, a second correction, `/handoff` | Turns a repeated mistake or session friction into a hook, a check or a rule, with the user's OK. |
| `.claude/skills/plain/` | `/plain`, "what changed?", every pull request | Explains a change in plain words for a non-developer; `/pr-body` puts it in an "In plain words" section. |
| `.claude/skills/verify/` | `/verify`, a review on a pull request | Checks each review comment against the code, then fixes it or answers with a reason. |
| `.claude/skills/distill/` | `/distill`, "too long", a length warning from `scripts/check.sh` | Shortens a text and checks item by item that nothing needed was lost. |

`grill-me`, `questionnaire`, `wait-what`, `pr-body` and `diagnosing-bugs` are adapted from github.com/mattpocock/skills
(MIT); `never-again`, `plain`, `verify` and `distill` from github.com/integralist/agent-skills. Both in
`.claude/skills/THIRD-PARTY.md`.

The scripts hold no project data. Everything project-specific is in `.claude/ground-truth.conf`.

Only in this master copy (not copied to the repos):

| File | When | What |
|---|---|---|
| `scripts/check.sh` | every pull request (`.github/workflows/check.yml`), and before a push | Every script parses, `settings.json` is valid and its hook files exist, every hook's tests pass, the cheat sheet lists every skill, and the freeze holds (no more hooks or skills than on 2026-11-10). |
| `.github/workflows/sync.yml`, `scripts/sync-all.sh` | every push to `main` that changes the workflow; by hand from the Actions tab | Runs `scripts/check.sh`, then opens or updates the "Workflow update" pull request in each repo of `sync/repos.txt` and merges it when it needs no step by hand. |
| `CHANGES.md`, `scripts/changes-since.sh` | read by the sync | What changed, in plain words, one line per change. The sync pull request opens with the lines added since that repo's last sync, grouped into "Changes for you", "New" and "Fixed"; the commits follow, folded. |
| `scripts/sync.sh`, `scripts/sync-settings.mjs` | inside the sync; by hand to try a change | Brings one checkout up to this copy (README.md, "How the sync works"). |
| `sync/repos.txt` | read by the sync | The repos that get the workflow, one `owner/repo` per line. |
| `.github/workflows/collect-lessons.yml`, `scripts/collect-lessons.sh` | daily 06:17 UTC; by hand from the Actions tab | Collects the "## Shared" lessons of every repo in `sync/repos.txt` into `.claude/rules/shared-lessons.md` and opens or updates one "Shared lessons from the repos" pull request to `main` (README, "Shared lessons"). `DRY_RUN=1` tries it without a pull request. |
| `scripts/drift-check.sh` | Mondays 07:43 Budapest, scheduled task "Workflow drift check" | Compares each repo's `.claude/workflow-version` with `main` here and lists the workflow commits it is missing. The task opens or updates one Backlog issue here when a repo is behind. |

## Shared lessons

A lesson that holds in every repo (Claude Code, the PCs and tools, how Claude works with the user) should not stay in
the one repo that learned it. The way it travels, without anyone having to notice:

1. A session writes it under `## Shared (goes to every repo)` at the end of its repo's `notes/lessons.md`, on the
   work branch. `.claude/hooks/lesson-check.mjs` asks Claude to sort every new lesson, so this does not depend on
   the user catching it. (Cloud sessions cannot push to this repo, so the lesson waits in its own repo.)
2. Every day `scripts/collect-lessons.sh` reads those sections (with the sync's token), appends the new ones to
   `.claude/rules/shared-lessons.md` under "New from the repos" and opens or updates one pull request to `main`.
3. Balázs merges it (moving each line into its section first, or leaving that to the next session here; a narrow
   fact goes to `.claude/lessons/shared-facts.md` instead, which loads only when its topic comes up). The sync
   then brings the file to every repo; Claude Code loads it by itself.
4. In each repo the lesson check sees the lesson in the shared file and has Claude delete the copy from
   `notes/lessons.md`, so it loads once.

In this repo a shared lesson goes straight into `.claude/rules/shared-lessons.md` (an everyday rule) or
`.claude/lessons/shared-facts.md` (a narrow fact). Their stale-able facts are checked like `notes/lessons.md`:
`ground-truth.sh` always reads both files too.

The collector's pull request is opened with the Actions token, so its checks do not run by themselves; the sync
runs `scripts/check.sh` after the merge. The repository setting "Allow GitHub Actions to create and approve pull
requests" must be on (Settings, Actions, General, Workflow permissions).

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

**Latest or pinned.** Every repo follows the latest version. The sync merges its own pull request right away
(Balázs, 2026-10-26: the change was already checked and merged here), except one with a "Do before merging" list or
with hand commits on `workflow-sync`: that one waits for the user. If the merge fails (e.g. the repo allows no merge
commits), the pull request stays open with a warning in the Actions log.

**The token.** The sync writes to repos of another owner (Kol-Lab-Design-Kft), so it needs a token in this repo's
secret `SYNC_TOKEN`:

1. GitHub, Settings, Developer settings, Fine-grained tokens, Generate new token.
2. Resource owner: Kol-Lab-Design-Kft. Repository access: only the repos in `sync/repos.txt`.
3. Permissions: Contents read and write, Pull requests read and write. Expiry: up to a year; note the date in
   `notes/lessons.md` with a `(check by YYYY-MM-DD)` tag a week before it.
4. This repo, Settings, Secrets and variables, Actions, New repository secret: name `SYNC_TOKEN`, the token as value.
5. Actions tab, "sync", Run workflow: one pull request per repo, or "already current".

A fine-grained token reaches one owner only. Repos of this repo's own owner (furythestunner, e.g. claude-mods) use a
second token in the secret `SYNC_TOKEN_OWN`: the same steps with Resource owner furythestunner, only those repos, and
the secret named `SYNC_TOKEN_OWN`.

A new repo added later needs to be added to its owner's token's repository list too.

## Add it to a repo

1. Add `owner/repo` to `sync/repos.txt` (and to its owner's token's repository list), merge to `main`. The sync opens the
   repo's first "Workflow update" pull request, with a template `ground-truth.conf` when the repo has none.
2. In that pull request's branch, fill in `.claude/ground-truth.conf`: `REPOS`, `WORK_BRANCH`, `HANDOFF`, `DOCS`,
   `USER_NAME`, and `CHECK` if the repo has a check command (the push check runs it before every push). Then merge it.
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

## Delete merged branches by themselves

Only for a public repo, or a repo on a paid GitHub plan. Today that is this repo alone: the 4 project repos are
private on the free plan, where GitHub does not enforce rulesets (`.claude/lessons/shared-facts.md`). There,
leave "Automatically delete head branches" off, or the work branch is deleted at its next merge to `main`.

Once per repo that qualifies (about 2 min). Do step 1 first: without it, GitHub would delete the work branch when
it is merged to `main`.

1. The repo on GitHub, Settings, Rules, Rulesets, New ruleset, New branch ruleset. Name: `keep main and work branch`.
   Enforcement status: Active. Target branches, Add target, Include by pattern: `main`; again for the work branch
   (e.g. `dev-test`). Under Rules, tick only "Restrict deletions". Create.
2. Settings, General, scroll to Pull Requests, tick "Automatically delete head branches".
3. Test once: the next merged pull request from the work branch to `main` must leave the work branch in place
   (the Branches page lists it). If it is gone, recreate it from `main` and tell Claude.

The branches already merged stay: delete those once on the Branches page (the bin icon).

## Merge by itself

Only for a public repo, or a repo on a paid GitHub plan (today: this repo alone). In a private repo on the free
plan "Allow auto-merge" is greyed out; there Claude merges by hand once the checks pass.

Once per repo that qualifies (about 2 min), so Claude can turn on auto-merge and GitHub waits for the checks
before merging (`.claude/rules/workflow.md`, Merging):

1. The repo on GitHub, Settings, General, scroll to Pull Requests, tick "Allow auto-merge".
2. Settings, Rules, Rulesets, New ruleset, New branch ruleset. Name: `checks before main`. Enforcement status:
   Active. Add target, Include by pattern: `main` only (not the work branch: a required check there blocks every
   direct push to it). Tick "Require status checks to pass", Add checks, type `check` and pick it. Create. (A repo with no check yet: skip this step; Claude then merges once the pull request
   can be merged.)

## When a workflow update breaks the sessions

The sync merges itself into every repo, so a broken hook reaches all of them. Two ways out:

- **Turn the hooks off in one repo** (about 1 min): on GitHub open the repo, pick its work branch, Add file, Create
  new file, name it `.claude/workflow-off` (empty), Commit changes. Start a new session: its first reply says
  WORKFLOW OFF, and no hook runs. Delete the file to turn them back on. Claude cannot create this file. If the
  first reply still shows no WORKFLOW OFF line (the session start itself is broken), create the same file in
  `main` too. Sessions with several repos need the current `cloud/setup-script.sh` in the environment.
- **Take the change back everywhere:** here, revert the pull request that broke it (the pull request's page,
  Revert, then merge that one). The sync then brings the old files to every repo.

## Usage record

`notes/usage.md` in each repo counts how often each hook fired and each skill was used, with the first and last
day. `.claude/hooks/run.mjs` writes it; it goes into the handoff's commit. A hook or skill with no row never
fired there. Read it before cutting or keeping something: the count decides, not a guess. It is a count, not a
ledger: a cloud session that ends without a handoff commit loses its lines, and two machines that both changed a
row give a merge conflict (take either side).

## Rules of this setup

The rulings on the workflow itself are in `questions.md` §2, as in every repo (moved there on 2026-11-10).
