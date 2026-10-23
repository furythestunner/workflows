# Handoff

Updated: 2026-10-23

## Next

1. Roll the workflow out to intranet, KolLab.extension and website (#5): all three are on 4603484, three
   workflow commits behind `main` (the weekly drift check lists them; README.md, "Only in this master copy").
2. Once Balázs confirms the uploaded claude.ai skills load in a cloud session: remove the five repo copies here and
   in each project repo (https://github.com/furythestunner/workflows/issues/14).

## Waiting for Balázs

- Drift check: disable it (Claude may, with an OK), then recreate it from the claude.ai scheduled tasks page with
  furythestunner/workflows and the three Kol-Lab-Design-Kft repos selected; same prompt.
- Pull request https://github.com/furythestunner/workflows/pull/13 (self-hosting files, CI, the review rule, the
  drift check, the skill packages): test and merge.
- Upload the five zips from `bash scripts/package-skills.sh` in claude.ai (Settings, Capabilities, Skills), then
  open a new cloud session and check they are listed.
- Labels on #5, #6 and #12; #12 can be closed (dev-test exists on GitHub).

## Running

- Scheduled task "Workflow drift check" (Mondays 07:43 Budapest, phone notification). The test run on 2026-10-23
  FAILED: the session could not attach the private project repos (no add_repo, GitHub 403), so nothing was
  checked. Fix waits for Balázs (below).

## Unfinished

Nothing on one disk only.
