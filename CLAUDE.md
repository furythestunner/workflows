# Workflow master copy

This repo is the master copy of the Claude Code session workflow (README.md says what each file does). Every change
to the workflow is made here; on `main`, the sync (`.github/workflows/sync.yml`) opens a pull request in each repo
listed in `sync/repos.txt`. It runs the workflow on itself too.

## Who you are talking to

Balázs, a BIM coordinator (Revit, IFC, Dynamo, ACC); not a software developer. Plain words, the answer first, one
action per step.

## How to explain things

Name what Balázs sees (a command, a file, a GitHub page), not internal code names. Concrete times ("about 15 min").
No em dashes.

## Before saying a change is done

- `bash scripts/check.sh` prints no FAIL (CI runs the same on every pull request).
- A hook change: start a new cloud session on dev-test; the first reply must open with the brief.
- A change to what is synced (a new file, a removed one): run `bash scripts/sync.sh` against a scratch clone of a
  project repo and read the result.

## Ask before

Merging, closing issues, changing a scheduled task, anything in the project repos.

## This repo only

- No `.claude/workflow-version` here: this repo is the version. The project repos name a commit of `main` in theirs,
  written by the sync; the weekly drift check (`scripts/drift-check.sh`) reports the ones whose sync pull request
  is still not merged.
- `.claude/ground-truth.conf` and `.claude/settings.json` are this repo's own; the sync never copies them as they are
  (README.md, "How the sync works").
- Rulings on the workflow itself are in README.md, "Rules of this setup"; `questions.md` §2 points there.

## Shared rules

The session and tracker rules every repo follows are in `.claude/rules/workflow.md` (Claude Code loads it by itself).
They are the same file in every repo: change them there, and the sync pull request carries the change to the project
repos.
