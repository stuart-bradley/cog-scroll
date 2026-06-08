set shell := ["bash", "-eo", "pipefail", "-c"]

export PATH := home_directory() / "flutter/bin:" + env("PATH")

default: check

# Code generation (Drift + Riverpod)
codegen:
    dart run build_runner build --delete-conflicting-outputs

# Static analysis
analyze:
    flutter analyze --no-pub

# Format check (fails on unformatted code)
format-check:
    dart format --set-exit-if-changed .

# Auto-fix formatting
format:
    dart format .

# Unit + widget tests
test:
    flutter test --no-pub

# Full CI check (same as what runs on PRs)
check: codegen analyze format-check test

# Build debug APK
build-debug:
    flutter build apk --debug --no-pub

# Setup release signing (needs KEYSTORE_BASE64, STORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD)
release-sign:
    ./scripts/release-sign.sh

# Build release AAB
release-build:
    flutter build appbundle --release

# Deploy to Play Store (needs PLAY_STORE_JSON_KEY + track/status env vars)
release-deploy:
    ./scripts/release-deploy.sh

# Full release pipeline (local: verify, then sign/build/deploy)
release: check release-sign release-build release-deploy

# CI release pipeline: sign/build/deploy only. `just check` runs in a separate
# secret-free CI step so codegen/tests never see the signing/Play secrets.
release-ci: release-sign release-build release-deploy

# E2E tests (assumes emulator running)
e2e:
    flutter test --no-pub integration_test/ --timeout 300s

# CI-only: free disk space on GitHub runners
ci-free-disk:
    ./scripts/ci-free-disk.sh

# CI-only: enable KVM for Android emulator
ci-enable-kvm:
    ./scripts/ci-enable-kvm.sh

# Install dependencies + generate code
setup:
    flutter pub get
    just codegen

# Lint shell scripts
lint-scripts:
    shellcheck scripts/*.sh

# Clean build artifacts
clean:
    flutter clean
