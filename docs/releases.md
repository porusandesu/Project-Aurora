# Releases and canary rollouts

Pull requests and pushes to `main` run `.github/workflows/ci.yml` on GitHub-hosted runners. CI formats, analyzes, tests, builds Android arm32/arm64 APKs and an iOS simulator app, and keeps the Android APK as a short-lived artifact. Routine verification does not need to compile mobile builds locally.

## Manual release

From a reviewed commit on `main`, run the **Android release** workflow with:

- A new `MAJOR.MINOR.PATCH` version.
- `canary` for an early release or `stable` for a full release.
- A local feature cohort percentage. Canary accepts 1–99%; stable requires 100%.

The workflow validates and tests the source, writes the chosen rollout into the bundled `assets/feature_manifest.json`, builds Android arm32/arm64 APKs with a monotonically increasing build number, computes a SHA-256 checksum, then publishes a GitHub Release. Canary releases are marked pre-release. The APK, checksum, and manifest are attached to that release.

## How the feature cohort works

On first launch, Aurora creates one random bucket from 0 to 99 and stores it in the local SQLite metadata table. A feature is enabled when its manifest is on, its kill switch is off, the app version meets the minimum, and the local bucket falls inside the rollout percentage. The bucket never leaves the device and is not used as an analytics identifier. Clearing app data assigns a new bucket.

Only features compiled into the app can be enabled. Unknown feature names remain off. Feature flags cannot enable location upload, tracking, or other new data collection. The current build flags the journey planner, the only feature with a gate implemented so far.

## Limits

The manifest is bundled with each APK; changing a flag requires building and installing a new app release. This flow does not remotely update flags or datasets, stage installs through an app store, collect rollout health telemetry, or provide store signing credentials. The produced APK is a release candidate for manual review, not a store-ready signed package. Promote a canary only after reviewing its artifact and validating it on a closed device group.
