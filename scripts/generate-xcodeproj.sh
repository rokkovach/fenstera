#!/usr/bin/env bash
set -euo pipefail

echo "==> Generating Xcode project with xcodegen..."
if command -v xcodegen &>/dev/null; then
    xcodegen generate
    echo "==> Done! Open OpenCodeController.xcodeproj in Xcode."
else
    echo "==> xcodegen not found. Installing via brew..."
    brew install xcodegen
    xcodegen generate
    echo "==> Done! Open OpenCodeController.xcodeproj in Xcode."
fi
