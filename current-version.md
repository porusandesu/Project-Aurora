# Current version

**Updated:** 2026-11-19

**App version:** `1.0.0+1` (from `pubspec.yaml`)

**Repository state:** Initial implementation on `codex/build-aurora`; draft PR #1. No tagged app release is recorded in this repository.

## Current implementation

- Flutter mobile app targeting Android and iOS, with local SQLite storage seeded from a fictional sample dataset.
- Offline place search by canonical name or alias, with canonical-first results and an “Also called” label.
- Local direct and one-transfer journey planning; sample records include provenance/verification labels.
- No passenger sign-in, location permission, telemetry, or passenger-flow network calls.
- GitHub Actions workflows for formatting, tests, analysis, Android split-APK builds, and an iOS simulator build. Android canary/stable publishing is manual.
- Project-scoped Graphify knowledge graph and instructions.

The sample data is fictional and must not be used for travel. The app bundle currently contains the feature manifest and local cohort gate. **That rollout design is provisional:** the active product decision log still lists the choice of local cohorts versus store-managed rollout as undecided. Treat the current flag behavior as an implementation experiment until that decision is recorded.

## Dated repository change history

All repository implementation commits to date are dated **2026-11-19**:

- **2026-11-19 — `c60d37e`: Initial Aurora implementation.** Added the Flutter mobile app, SQLite sample catalogue, alias-aware search, direct/one-transfer planner, tests, local feature manifest and cohort gate, release configuration tooling, architecture/release documentation, GitHub Actions, and project Graphify files.
- **2026-11-19 — `8683b3f`: Release artifact correction.** Changed CI and Android release builds to produce separate ARM32, ARM64, and x86_64 APKs; attached each APK and checksums to releases; aligned release documentation.
- **2026-11-19 — `e73fb81`: Version record.** Added this current-version record.

The repository’s base commit, `f26e103` (2026-11-19), contains the starter README. The entries above describe the subsequent project changes on this feature branch.

## Active documentation alignment

Reviewed the active project overview, requirements, architecture/product decisions, implementation plan, changelog, build-gap report, agent instructions, and task board on **2026-11-19**. Archived and duplicate specifications were excluded. The source documentation’s current revision is v5; it requires staged work and proofs of concept before committing to map or desktop implementations.

Implemented in this repository: the synthetic offline catalogue and basic planner, alias search, local persistence, and hosted CI/release automation.

Still missing or partial against the active requirements: verified production data, dataset manifest integrity and atomic update/rollback, an offline geographic map, explicitly started background trip guidance, queued report submission, moderation, and a separate staff desktop application. These are not represented as available features here. Map and desktop implementation remain gated on the documented proof-of-concept results.

The canary workflow publishes app artifacts, but this is not store-managed staged rollout and does not collect health telemetry. No production data, private product names, internal decision identifiers, or real-world transport details are included in this public repository.

## Verification status

- Python release-configuration tests passed on 2026-11-19.
- Dart formatting passed on 2026-11-19.
- Full Flutter tests, analysis, and mobile builds are delegated to GitHub Actions to avoid heavy local builds on the 4 GB machine; consult PR #1 for their current status.
