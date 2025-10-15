#!/usr/bin/env bash
set -euo pipefail

# Apply "DEV" badge overlay to iOS app icons
# This helps visually distinguish development builds from production builds

ASSET_DIR="app/ios/Runner/Assets.xcassets/AppIcon-Dev.appiconset"
SCRIPT="scripts/ios/dev_icon_overlay.swift"

if [ ! -d "$ASSET_DIR" ]; then
  echo "AppIcon-Dev.appiconset not found at $ASSET_DIR" >&2
  exit 1
fi

if [ ! -f "$SCRIPT" ]; then
  echo "Swift overlay script not found at $SCRIPT" >&2
  exit 1
fi

count=0
for f in "$ASSET_DIR"/*.png; do
  [ -e "$f" ] || continue
  xcrun swift "$SCRIPT" "$f" "$f"
  count=$((count+1))
  echo "Overlay applied: $(basename "$f")"
done

echo "Done. Overlay applied to $count icons."

