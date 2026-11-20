## What and why

One or two sentences. Task reference: 

## Scope

- [ ] The change is one small slice (about a day of work or less)
- [ ] Only the files named in the task brief were changed

## Privacy and safety (all must be true, or explain)

- [ ] No new dependency (or the dependency list was changed in a reviewed commit)
- [ ] No new network call, permission, analytics, ad or tracking code
- [ ] No sign-in, device or user identifier added
- [ ] No private names, real places, local paths or secrets in any file, commit message or screenshot
- [ ] Sample data is still clearly fictional

## Evidence

- [ ] Tests added or updated for the behaviour (list the cases)
- [ ] `dart format`, `flutter analyze`, `flutter test` and `python3 tools/privacy_check.py` pass
- [ ] Impact of changes to shared code checked with the code graph
- [ ] Screenshot or short recording attached for UI changes

## Rollout

- [ ] Features that can fail are behind a flag with a kill switch, off by default
- [ ] How to undo this change: 
