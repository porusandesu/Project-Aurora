# Graph Report - Project-Aurora  (2026-11-19)

## Corpus Check
- 45 files · ~11,822 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 35 file(s) not represented in the graph (top: .xml 7, (none) 6, .plist 4)
- WARNING: 35 of 109 files seen (32%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 444 nodes · 533 edges · 27 communities (18 shown, 9 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 16 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f26e1031`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Win32Window
- main.dart
- my_application.cc
- feature_flags.dart
- models.dart
- with
- FlutterWindow
- steps
- utils.cpp
- transit_database.dart
- AppDelegate
- pubspec.yaml
- Architecture
- channel
- configure_release.py
- StatelessWidget
- analysis_options.yaml
- AuroraShell
- models_test.dart
- MainActivity.kt
- AGENTS.md
- LaunchImage.imageset/README.md

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 27 edges
2. `FlutterWindow` - 12 edges
3. `with` - 8 edges
4. `configure_manifest()` - 8 edges
5. `WindowClassRegistrar` - 8 edges
6. `_MyApplication` - 7 edges
7. `channel` - 6 edges
8. `steps` - 6 edges
9. `ConfigureManifestTest` - 6 edges
10. `FlutterWindow::OnCreate()` - 6 edges

## Surprising Connections (you probably didn't know these)
- `FlutterWindow::OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/flutter/generated_plugin_registrant.cc
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `FlutterWindow` --inherits--> `Win32Window`  [EXTRACTED]
  windows/runner/flutter_window.h → windows/runner/win32_window.h

## Import Cycles
- None detected.

## Communities (27 total, 9 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.06
Nodes (23): FlutterWindow::OnCreate(), Win32Window::Destroy(), Win32Window::GetClientArea(), Win32Window::GetHandle(), Win32Window::OnCreate(), Win32Window::Show(), EnableFullDpiSupportIfAvailable(), EnableNonClientDpiScaling (+15 more)

### Community 1 - "main.dart"
Cohesion: 0.05
Nodes (37): _AppData, _appVersion, build, _canvas, createState, _data, _database, datasetVersion (+29 more)

### Community 2 - "my_application.cc"
Cohesion: 0.09
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 3 - "feature_flags.dart"
Cohesion: 0.07
Nodes (25): bucket, core, currentParts, enabled, FeatureFlagSnapshot, FeatureRule, fromJson, _getOrCreateRolloutBucket (+17 more)

### Community 4 - "models.dart"
Cohesion: 0.07
Nodes (26): aliases, alightingStop, area, boardingStop, canonicalName, description, id, JourneyLeg (+18 more)

### Community 5 - "with"
Cohesion: 0.07
Nodes (26): concurrency, cancel-in-progress, group, jobs, verify, name, on, pull_request (+18 more)

### Community 6 - "FlutterWindow"
Cohesion: 0.08
Nodes (7): RegisterPlugins(), FlutterWindow::OnDestroy(), FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_, Win32Window::OnDestroy()

### Community 7 - "steps"
Cohesion: 0.08
Nodes (24): concurrency, cancel-in-progress, group, GH_TOKEN, RELEASE_CHANNEL, RELEASE_VERSION, ROLLOUT_PERCENTAGE, jobs (+16 more)

### Community 8 - "utils.cpp"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 9 - "transit_database.dart"
Cohesion: 0.09
Nodes (13): _assets, close, _database, datasetVersion, destinationRoutes, options, originRoutes, places (+5 more)

### Community 10 - "AppDelegate"
Cohesion: 0.11
Nodes (6): Flutter, AppDelegate, SceneDelegate, RunnerTests, UIKit, XCTest

### Community 11 - "pubspec.yaml"
Cohesion: 0.11
Nodes (18): dependencies, flutter, path, sqflite, description, dev_dependencies, flutter_lints, flutter_test (+10 more)

### Community 12 - "Architecture"
Cohesion: 0.11
Nodes (15): Architecture, Current flow, Local schema, Platform boundary, Sample data boundary, Search and route calculation, How the feature cohort works, Limits (+7 more)

### Community 13 - "channel"
Cohesion: 0.11
Nodes (18): default, description, options, required, type, channel, rollout_percentage, version (+10 more)

### Community 14 - "configure_release.py"
Cohesion: 0.19
Nodes (3): ConfigureManifestTest, configure_manifest(), main()

### Community 15 - "StatelessWidget"
Cohesion: 0.14
Nodes (13): AuroraApp, _DiscoverPage, _EmptyMessage, _JourneyCard, _JourneyLegRow, _PlaceCard, _PlannerPromo, _RoutesPage (+5 more)

### Community 16 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 17 - "AuroraShell"
Cohesion: 0.40
Nodes (4): AuroraShell, _AuroraShellState, _PlanPage, _PlanPageState

## Knowledge Gaps
- **112 isolated node(s):** `XCTest`, `FeatureRule`, `enabled`, `rolloutPercentage`, `minimumAppVersion` (+107 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 269 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `utils.cpp`, `FlutterWindow`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **What connects `XCTest`, `FeatureRule`, `enabled` to the rest of the system?**
  _112 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.06397306397306397 - nodes in this community are weakly interconnected._
- **Why does `FlutterWindow` connect `FlutterWindow` to `Win32Window`, `utils.cpp`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Should `main.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.045454545454545456 - nodes in this community are weakly interconnected._
- **Why does `FeatureFlagSnapshot` connect `feature_flags.dart` to `main.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.08735632183908046 - nodes in this community are weakly interconnected._