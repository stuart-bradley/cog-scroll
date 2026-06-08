#!/usr/bin/env bash
set -euo pipefail

: "${PLAY_STORE_JSON_KEY:?PLAY_STORE_JSON_KEY env var required}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PLAY_STORE_JSON_KEY_PATH="$REPO_ROOT/play-store-key.json"

printf '%s' "$PLAY_STORE_JSON_KEY" > "$PLAY_STORE_JSON_KEY_PATH"
cd "$REPO_ROOT/android" && bundle exec fastlane deploy
