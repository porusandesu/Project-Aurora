#!/usr/bin/env python3
"""Set local feature rollout rules for a manually approved release."""

import json
import re
import sys
from pathlib import Path


def configure_manifest(
    manifest: dict, version: str, channel: str, percentage: int
) -> dict:
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError("version must use MAJOR.MINOR.PATCH")
    if channel not in {"canary", "stable"}:
        raise ValueError("channel must be canary or stable")
    if channel == "stable" and percentage != 100:
        raise ValueError("stable releases must use a 100 percent rollout")
    if channel == "canary" and not 1 <= percentage <= 99:
        raise ValueError("canary rollout must be between 1 and 99 percent")

    manifest["manifestVersion"] = f"{version}-{channel}"
    manifest["releaseChannel"] = channel
    manifest["appMinimumVersion"] = version
    for rule in manifest["features"].values():
        rule["rolloutPercentage"] = percentage
        rule["minimumAppVersion"] = version
    return manifest


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit(
            "usage: configure_release.py VERSION (canary|stable) PERCENTAGE"
        )

    version, channel, raw_percentage = sys.argv[1:]
    try:
        percentage = int(raw_percentage)
    except ValueError as error:
        raise SystemExit("percentage must be an integer") from error

    manifest_path = Path("assets/feature_manifest.json")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    try:
        configure_manifest(manifest, version, channel, percentage)
    except ValueError as error:
        raise SystemExit(str(error)) from error
    manifest_path.write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
