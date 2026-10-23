# Handoff

## Next

1. Roll the workflow out to intranet, KolLab.extension and website (#5): all three are on 4603484, three
   workflow commits behind `main` (`bash scripts/drift-check.sh` lists them).
2. Once Balázs confirms the uploaded claude.ai skills load in a cloud session: remove the five repo copies here and
   in each project repo (the follow-up issue).

## Waiting for Balázs

- The pull request dev-test → `main` with the self-hosting files, CI, the review rule, the drift check and the
  skill packages: test and merge.
- Upload the five zips from `bash scripts/package-skills.sh` in claude.ai (Settings, Capabilities, Skills), then
  open a new cloud session and check they are listed.
- Labels on #5, #6 and #12; #12 can be closed (dev-test exists on GitHub).

## Unfinished

Nothing on one disk only.
