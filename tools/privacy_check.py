#!/usr/bin/env python3
"""Fail the build when a change breaks the project's privacy rules.

Checks (standard library only):
  1. Dependencies must be on tools/allowed_dependencies.txt and must not look
     like ad, analytics or tracking packages.
  2. Dart code must not use network APIs unless the file is listed in
     tools/network_allowlist.txt.
  3. The main Android manifest and iOS Info.plist must not request
     permissions that are not listed in tools/approved_permissions.txt.
  4. Tracked files must not contain local machine paths.
  5. Tracked files must not contain private terms. The pattern comes from the
     PRIVATE_TERMS environment variable (store it as a repository secret so
     the list itself is never published). Matches are reported by file and
     line number only, because CI logs of a public repository are public.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

DENY_SUBSTRINGS = (
    "firebase", "analytics", "admob", "google_mobile_ads", "crashlytics",
    "sentry", "mixpanel", "amplitude", "segment", "appsflyer", "adjust",
    "facebook", "onesignal", "posthog", "branch_sdk", "flutter_branch",
)
NETWORK_PATTERNS = (
    re.compile(r"package:(http|dio|web_socket_channel|socket_io_client)\b"),
    re.compile(r"\b(HttpClient|WebSocket|RawSocket|RawDatagramSocket)\b"),
    re.compile(r"\bSocket\.connect\b"),
)
LOCAL_PATH = re.compile(r"(/home/[A-Za-z0-9._-]+/|/Users/[A-Za-z0-9._-]+/|[A-Za-z]:\\Users\\)")
ANDROID_PERMISSION = re.compile(r'uses-permission[^>]*android:name="([^"]+)"')
IOS_KEY = re.compile(r"<key>(NS[A-Za-z]+UsageDescription|UIBackgroundModes)</key>")
TEXT_SUFFIXES = {
    ".dart", ".yaml", ".yml", ".md", ".txt", ".json", ".py", ".kt", ".kts",
    ".xml", ".plist", ".gradle", ".properties", ".html", ".sh", ".toml",
}


def read_list(path: Path) -> set[str]:
    if not path.exists():
        return set()
    items = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            items.add(line)
    return items


def tracked_files(root: Path) -> list[Path]:
    try:
        out = subprocess.run(
            ["git", "-C", str(root), "ls-files"],
            check=True, capture_output=True, text=True,
        ).stdout.splitlines()
        return [root / name for name in out if (root / name).is_file()]
    except (OSError, subprocess.CalledProcessError):
        skip = {".git", "build", ".dart_tool"}
        found = []
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in skip]
            found += [Path(dirpath) / f for f in filenames]
        return found


def is_text(path: Path) -> bool:
    return path.suffix.lower() in TEXT_SUFFIXES and path.stat().st_size < 2_000_000


def check_dependencies(root: Path) -> list[str]:
    pubspec = root / "pubspec.yaml"
    if not pubspec.exists():
        return []
    allowed = read_list(root / "tools" / "allowed_dependencies.txt")
    errors, section = [], None
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        if re.match(r"^(dependencies|dev_dependencies):", line):
            section = line.split(":")[0]
            continue
        if re.match(r"^\S", line):
            section = None
            continue
        match = re.match(r"^  ([a-z0-9_]+):", line)
        if section and match:
            name = match.group(1)
            if any(bad in name for bad in DENY_SUBSTRINGS):
                errors.append(f"pubspec.yaml: '{name}' looks like an ad, analytics or tracking package")
            elif name not in allowed:
                errors.append(f"pubspec.yaml: '{name}' is not in tools/allowed_dependencies.txt (add it in a reviewed change)")
    return errors


def check_network(root: Path) -> list[str]:
    allowed = read_list(root / "tools" / "network_allowlist.txt")
    errors = []
    lib = root / "lib"
    if not lib.exists():
        return errors
    for path in sorted(lib.rglob("*.dart")):
        rel = path.relative_to(root).as_posix()
        if rel in allowed:
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if any(p.search(line) for p in NETWORK_PATTERNS):
                errors.append(f"{rel}:{number}: network API used (list the file in tools/network_allowlist.txt after review)")
    return errors


def check_permissions(root: Path) -> list[str]:
    approved = read_list(root / "tools" / "approved_permissions.txt")
    errors = []
    manifest = root / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if manifest.exists():
        for name in ANDROID_PERMISSION.findall(manifest.read_text(encoding="utf-8")):
            if name not in approved:
                errors.append(f"AndroidManifest.xml: permission '{name}' is not in tools/approved_permissions.txt")
    plist = root / "ios" / "Runner" / "Info.plist"
    if plist.exists():
        for key in IOS_KEY.findall(plist.read_text(encoding="utf-8")):
            if key not in approved:
                errors.append(f"Info.plist: key '{key}' is not in tools/approved_permissions.txt")
    return errors


def check_paths(root: Path, files: list[Path]) -> list[str]:
    errors = []
    for path in files:
        if not is_text(path):
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
            if LOCAL_PATH.search(line):
                errors.append(f"{path.relative_to(root).as_posix()}:{number}: contains a local machine path")
                break
    return errors


def check_private_terms(root: Path, files: list[Path], pattern: str | None) -> tuple[list[str], str]:
    if not pattern:
        return [], "PRIVATE_TERMS is not set, so the private-term check was skipped"
    regex = re.compile(pattern, re.IGNORECASE)
    errors = []
    for path in files:
        if not is_text(path):
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
            if regex.search(line):
                errors.append(f"{path.relative_to(root).as_posix()}:{number}: contains a private term (term not shown)")
    return errors, "private-term check ran"


def run(root: Path, pattern: str | None = None) -> int:
    files = tracked_files(root)
    errors = []
    errors += check_dependencies(root)
    errors += check_network(root)
    errors += check_permissions(root)
    errors += check_paths(root, files)
    term_errors, note = check_private_terms(root, files, pattern)
    errors += term_errors
    print(f"privacy_check: {note}")
    if errors:
        print(f"privacy_check: {len(errors)} problem(s) found")
        for error in errors:
            print(f"  - {error}")
        return 1
    print("privacy_check: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(run(Path(__file__).resolve().parents[1], os.environ.get("PRIVATE_TERMS")))
