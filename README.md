# Aurora

Aurora is an offline-first journey-planning app. This repository contains an early mobile implementation with a local SQLite catalogue, place search, and simple direct or one-transfer route planning.

## Run locally

Requires Flutter 3.47.7 stable and Dart 3.13.5 or later.

```sh
flutter pub get
flutter run
```

The passenger app currently targets Android and iOS. The desktop runners are not part of this release; desktop support needs a separate platform review.

## Included in this build

- A local SQLite database initialized from a bundled dataset.
- Place search by canonical name and alias. Alias results keep the canonical name first and show `Also called: …`.
- Direct and one-transfer journey options calculated locally.
- Provenance and verification labels for catalogue records.
- A local feature flag manifest with persistent, on-device rollout buckets and kill switches.
- GitHub Actions for pull request checks, Android builds, and manually approved canary or stable releases.
- No sign-in, location permission, analytics, or network calls in the passenger flow.
- A clearly marked fictional sample dataset. It is not travel information.

## Data and privacy

The included dataset is synthetic and exists only to demonstrate the app. Replace it with reviewed, licensed, and sourced data before any real-world use. Sample records are marked as such in the UI. The app does not collect a passenger profile or send searches, journeys, or coordinates to a server.

The current build does not include remote dataset updates, maps, GPS guidance, reports, or administration tools. Those features require additional data-integrity and platform work before they can be represented as available. Feature flags ship in the app bundle; this build does not fetch remote flag changes. See [docs/releases.md](docs/releases.md) for the release flow and its limits.

## Development

```sh
dart format lib test
flutter analyze
flutter test
```

See [docs/architecture.md](docs/architecture.md) for the local data model and implementation boundaries.
