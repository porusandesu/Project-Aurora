# Graph Report - Project-Aurora  (2026-11-25)

## Corpus Check
- 68 files · ~20,780 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 38 file(s) not represented in the graph (top: (none) 7, .xml 7, .plist 4)
- WARNING: 38 of 138 files seen (28%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 729 nodes · 908 edges · 45 communities (31 shown, 14 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 16 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2c54cf08`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- win32_window.cpp
- aurora_shell.dart
- my_application.cc
- feature_flags.dart
- models.dart
- with
- utils.cpp
- steps
- main.dart
- transit_database.dart
- AppDelegate
- pubspec.yaml
- Architecture
- shared_place_message.dart
- privacy_check.py
- plus_code.dart
- analysis_options.yaml
- feature_flags_test.dart
- models_test.dart
- MainActivity.kt
- AGENTS.md
- LaunchImage.imageset/README.md
- PrivacyCheckTests
- Development workflow
- updates
- Current version
- pull_request_template.md
- dataset_update.dart
- dataset_update_test.dart
- flutter_window.cpp
- FlutterWindow
- .Create
- Win32Window
- .MessageHandler
- shared_place_message_test.dart
- directions_to_point.dart
- shared_place_en.dart

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 27 edges
2. `PrivacyCheckTests` - 13 edges
3. `FlutterWindow` - 12 edges
4. `make()` - 11 edges
5. `run()` - 9 edges
6. `Development workflow` - 9 edges
7. `with` - 9 edges
8. `WindowClassRegistrar` - 8 edges
9. `configure_manifest()` - 8 edges
10. `_MyApplication` - 7 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `FlutterWindow` --inherits--> `Win32Window`  [EXTRACTED]
  windows/runner/flutter_window.h → windows/runner/win32_window.h
- `FlutterWindow::OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/flutter/generated_plugin_registrant.cc
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc

## Import Cycles
- None detected.

## Communities (45 total, 14 thin omitted)

### Community 0 - "win32_window.cpp"
Cohesion: 0.16
Nodes (5): Win32Window::Show(), EnableNonClientDpiScaling, WindowClassRegistrar, class_registered_, instance_

### Community 1 - "aurora_shell.dart"
Cohesion: 0.08
Nodes (28): AppData, AuroraShell, _AuroraShellState, build, createState, data, _database, datasetVersion (+20 more)

### Community 2 - "my_application.cc"
Cohesion: 0.09
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 3 - "feature_flags.dart"
Cohesion: 0.07
Nodes (28): bucket, core, currentParts, directory, enabled, FeatureFlagSnapshot, FeatureRule, fromJson (+20 more)

### Community 4 - "models.dart"
Cohesion: 0.05
Nodes (40): accuracyMetres, aliases, alightingStop, area, boardingNote, boardingStop, canonicalName, changes (+32 more)

### Community 5 - "with"
Cohesion: 0.06
Nodes (36): concurrency, cancel-in-progress, group, PRIVATE_TERMS, runs-on, steps, timeout-minutes, jobs (+28 more)

### Community 6 - "utils.cpp"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 7 - "steps"
Cohesion: 0.05
Nodes (43): default, description, options, required, type, concurrency, cancel-in-progress, group (+35 more)

### Community 8 - "main.dart"
Cohesion: 0.07
Nodes (36): AuroraApp, _DiscoverPage, _EmptyMessage, _JourneyCard, _JourneyLegRow, onPlan, onQuery, onRetry (+28 more)

### Community 9 - "transit_database.dart"
Cohesion: 0.07
Nodes (24): activateStagedDataset, add, _assets, close, _database, datasetVersion, exportDataset, options (+16 more)

### Community 10 - "AppDelegate"
Cohesion: 0.11
Nodes (6): Flutter, AppDelegate, SceneDelegate, RunnerTests, UIKit, XCTest

### Community 11 - "pubspec.yaml"
Cohesion: 0.10
Nodes (19): dependencies, crypto, flutter, path, sqflite, description, dev_dependencies, flutter_lints (+11 more)

### Community 12 - "Architecture"
Cohesion: 0.11
Nodes (15): Architecture, Current flow, Local schema, Platform boundary, Sample data boundary, Search and route calculation, How the feature cohort works, Limits (+7 more)

### Community 13 - "shared_place_message.dart"
Cohesion: 0.05
Nodes (33): buildSharedPlaceMessage, cleanNote, code, codeLength, current, currentDate, date, day (+25 more)

### Community 14 - "privacy_check.py"
Cohesion: 0.13
Nodes (13): ConfigureManifestTest, configure_manifest(), main(), check_backup(), check_dependencies(), check_network(), check_paths(), check_permissions() (+5 more)

### Community 15 - "plus_code.dart"
Cohesion: 0.09
Nodes (21): _alphabet, codeLength, contains, decode, _decodeUnchecked, east, encode, encodeRounded100m (+13 more)

### Community 16 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 17 - "feature_flags_test.dart"
Cohesion: 0.14
Nodes (9): insert, inserts, load, main, _manifest, _ManifestBundle, _MemorySettingsDatabase, query (+1 more)

### Community 18 - "models_test.dart"
Cohesion: 0.16
Nodes (5): main, main, _route, _stop, main

### Community 28 - "Development workflow"
Cohesion: 0.18
Nodes (10): Development workflow, Naming, Release checklist, Release signing (not yet set up), Repository settings (set once, in GitHub), Roles, Rules the privacy check enforces, Slice order (+2 more)

### Community 30 - "updates"
Cohesion: 0.25
Nodes (7): interval, updates, directory, open-pull-requests-limit, package-ecosystem, schedule, version

### Community 31 - "Current version"
Cohesion: 0.33
Nodes (5): Active documentation alignment, Current implementation, Current version, Dated repository change history, Verification status

### Community 32 - "pull_request_template.md"
Cohesion: 0.33
Nodes (5): Evidence, Privacy and safety (all must be true, or explain), Rollout, Scope, What and why

### Community 34 - "dataset_update.dart"
Cohesion: 0.08
Nodes (21): accuracy, activateStaged, data, DatasetPackage, DatasetUpdater, decode, directory, encode (+13 more)

### Community 35 - "dataset_update_test.dart"
Cohesion: 0.15
Nodes (7): _dataset, execute, main, _RecordingDatabase, statements, _temporaryDirectory, _updater

### Community 37 - "flutter_window.cpp"
Cohesion: 0.15
Nodes (6): RegisterPlugins(), FlutterWindow::OnCreate(), FlutterWindow::OnDestroy(), FlutterWindow::FlutterWindow(), Win32Window::OnCreate(), Win32Window::OnDestroy()

### Community 38 - "FlutterWindow"
Cohesion: 0.14
Nodes (3): FlutterWindow, flutter_controller_, project_

### Community 39 - ".Create"
Cohesion: 0.14
Nodes (8): Scale(), Point, x, y, Size, height, width, Win32Window::Win32Window()

### Community 40 - "Win32Window"
Cohesion: 0.17
Nodes (6): Win32Window::Destroy(), Win32Window::GetClientArea(), Win32Window, child_content_, quit_on_close_, window_handle_

### Community 42 - "shared_place_message_test.dart"
Cohesion: 0.25
Nodes (3): main, main, today

### Community 43 - "directions_to_point.dart"
Cohesion: 0.06
Nodes (33): approximateDistanceMetres, approximateWalkMetres, atTheStop, _atTheStopMetres, centralAngle, deltaLat, deltaLon, directionsToPoint (+25 more)

## Knowledge Gaps
- **240 isolated node(s):** `PointDirectionsResult`, `PointJourneyOption`, `NearbyStop`, `_earthRadiusMetres`, `_atTheStopMetres` (+235 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 459 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `win32_window.cpp`, `flutter_window.cpp`, `FlutterWindow`, `utils.cpp`, `.Create`, `.MessageHandler`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **What connects `PointDirectionsResult`, `PointJourneyOption`, `NearbyStop` to the rest of the system?**
  _240 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `aurora_shell.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07661290322580645 - nodes in this community are weakly interconnected._
- **Why does `Place` connect `main.dart` to `models.dart`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.08735632183908046 - nodes in this community are weakly interconnected._
- **Why does `FlutterWindow` connect `FlutterWindow` to `Win32Window`, `flutter_window.cpp`, `utils.cpp`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Should `feature_flags.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._