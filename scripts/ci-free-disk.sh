#!/usr/bin/env bash
set -euo pipefail
# Free disk space on GitHub Actions Ubuntu runners.
# No-op locally (directories won't exist).
sudo rm -rf /usr/share/dotnet /usr/local/lib/android/sdk/ndk \
    /opt/ghc /usr/local/share/powershell /usr/share/swift \
    /usr/local/.ghcup 2>/dev/null || true
sudo apt-get clean 2>/dev/null || true
df -h /
