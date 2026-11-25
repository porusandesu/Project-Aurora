# Development workflow

How changes get made here, whether a person or an AI agent writes them. The goal is small, checked, reversible steps.

## Roles

- **Owner:** decides what is built and what is allowed. Approves every merge.
- **Planner and reviewer:** writes task briefs and acceptance tests, then reads each pull request against them.
- **Builder agent:** implements one task on its own branch and opens a draft pull request.
- **CI:** the automatic gate. Nothing merges unless it is green.
- **Code graph:** used to see what a change touches before it is merged.

## The loop

1. **Decide.** Choices that affect privacy, data or scope are written down in the private decision log before any code.
2. **Slice.** One task is about a day of work or less, with a short list of acceptance tests.
3. **Brief.** Give the builder agent a task brief (template below). It must show a plan and wait for approval before changing files.
4. **Build.** One branch per task, for example `codex/<task>`. Tests are written with the code.
5. **Pull request.** Open it as a draft using the template. Link the task.
6. **Gates.** CI runs formatting, tests, analysis, the privacy check and the build. A red gate is fixed, never skipped.
7. **Review.** A person reads the diff. For changes to shared code, check the code graph for what depends on it. Prefer a second reviewer (another model or person) for anything touching data, storage or permissions.
8. **Merge.** Squash merge to `main` after CI is green and the owner approves.
9. **Release.** Canary first, then wider (see below). Update the changelog and mark the task done.

## Task brief template

```
Task: one sentence
Task reference:
Allowed to change: list of paths
Must not: add dependencies, network calls, permissions, analytics, identifiers;
          touch signing, manifests or the privacy tool unless listed here
Acceptance tests:
  - 
Plan first: show the plan and wait for approval
Done when: dart format, flutter analyze, flutter test and
           python3 tools/privacy_check.py all pass; PR template completed
```

## Slice order

1. Local data layer with stable IDs and migrations.
2. Search and journey calculation with tests.
3. Shared-place code encode and decode, tested against the published test data.
4. Interface shell from the approved designs.
5. Dataset update with checksum, staging and rollback.
6. Map, background location, reports and sharing, each only after its proof of concept passes.

## Naming

- During development, use only the project codename (Aurora) in code, strings, labels, file names, documentation, commit messages, branch names, pull request text, issues, screenshots and design exports.
- Never write the product's final public name anywhere in this repository before the final build. The privacy check blocks it when the `PRIVATE_TERMS` secret includes it.
- Test builds keep the codename application ID. A build with a different ID installs as a separate app, so testers must reinstall and local data does not carry over.
- At the final build the rename is one reviewed change (see the checklist in the private docs): application ID, app label, package name, iOS bundle ID, icons, store listing, privacy notice. Remove the old name from the blocklist at the same time.

## Repository settings (set once, in GitHub)

- Require a pull request and the `verify` and `privacy` checks before merging `main`.
- Block force pushes. Require linear history.
- Turn on Dependabot alerts and secret scanning.
- Add the repository secret `PRIVATE_TERMS`: a regular expression of private names. Use word boundaries, for example `\b(term1|term2)\b`, because plain substrings cause false matches. The check never prints the matched term.

## Release checklist

- [ ] A real release signing key is configured (see below). Never publish builds signed with the debug key.
- [ ] Version number and changelog updated.
- [ ] Checksums attached to the release.
- [ ] Canary first. Prefer the store's staged rollout over baking a percentage into the build.
- [ ] Features that can fail are behind a flag, off by default, with a kill switch.
- [ ] A way to undo: previous build kept, and a previous dataset to roll back to.

### Release signing (not yet set up)

1. Create a keystore once on a trusted computer with `keytool`. Keep a backup offline.
2. Store the keystore (base64), its password, key alias and key password as repository secrets.
3. In the release job, decode the keystore to a temporary file and point the Gradle release signing config at it.
4. Remove the debug-key fallback from the release build type.

## Rules the privacy check enforces

- Only dependencies listed in `tools/allowed_dependencies.txt`.
- No network APIs in `lib/` unless the file is listed in `tools/network_allowlist.txt`.
- No Android permissions or iOS usage keys unless listed in `tools/approved_permissions.txt`.
- No local machine paths in tracked files.
- No private terms (when `PRIVATE_TERMS` is set).

Changing any of these lists is a deliberate, reviewed decision.
