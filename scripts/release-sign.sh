#!/usr/bin/env bash
set -euo pipefail

: "${KEYSTORE_BASE64:?KEYSTORE_BASE64 env var required}"
: "${STORE_PASSWORD:?STORE_PASSWORD env var required}"
: "${KEY_ALIAS:?KEY_ALIAS env var required}"
: "${KEY_PASSWORD:?KEY_PASSWORD env var required}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

printf '%s' "$KEYSTORE_BASE64" | base64 --decode > "$REPO_ROOT/android/app/release.keystore"

printf 'storeFile=%s/android/app/release.keystore\nstorePassword=%s\nkeyAlias=%s\nkeyPassword=%s\n' \
    "$REPO_ROOT" "$STORE_PASSWORD" "$KEY_ALIAS" "$KEY_PASSWORD" \
    > "$REPO_ROOT/android/key.properties"

echo "Signing configured."
