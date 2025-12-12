#!/usr/bin/env bash
set -euo pipefail

# Launch Flutter app in production mode
# API base URL points to production backend

cd "$(dirname "$0")/../expotoworld_app"
flutter run --dart-define=API_BASE=https://device-api.expotoworld.com "$@"

