#!/usr/bin/env bash
set -euo pipefail

# Runs SwiftFormat and SwiftLint if available. Skips gracefully otherwise.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXIT_CODE=0

if command -v swiftformat >/dev/null 2>&1; then
  echo "[lint] Running swiftformat..."
  swiftformat "$ROOT_DIR" || EXIT_CODE=$?
else
  echo "[lint] swiftformat not installed; skipping"
fi

if command -v swiftlint >/dev/null 2>&1; then
  echo "[lint] Running swiftlint..."
  swiftlint --quiet || EXIT_CODE=$?
else
  echo "[lint] swiftlint not installed; skipping"
fi

exit $EXIT_CODE

