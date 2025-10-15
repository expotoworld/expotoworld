#!/usr/bin/env bash
set -euo pipefail

# Launch Flutter app in development mode for Android emulator
# API base URL points to Android emulator's host machine (10.0.2.2)

cd "$(dirname "$0")/../app"
flutter run --flavor dev --dart-define=API_BASE=http://10.0.2.2:8787 "$@"

