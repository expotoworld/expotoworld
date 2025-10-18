#!/usr/bin/env bash
set -euo pipefail

# Launch Flutter app in production mode
# API base URL points to production backend

cd "$(dirname "$0")/../app"
flutter run --flavor prod --dart-define=API_BASE=https://device-api.expotoworld.com "$@"

