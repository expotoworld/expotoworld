#!/usr/bin/env bash
set -euo pipefail

# Launch Flutter app in development mode for iOS simulator
# API base URL points to localhost (127.0.0.1)

cd "$(dirname "$0")/../app"
flutter run --flavor dev --dart-define=API_BASE=http://127.0.0.1:8787 "$@"

