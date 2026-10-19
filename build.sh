#!/bin/bash
# Builds DragWheel.app. Usage: ./build.sh            → build/DragWheel.app
#                              ./build.sh --install  → also copies to /Applications and launches it
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v swift >/dev/null; then
  echo "Swift not found. Install Apple's command line tools first:  xcode-select --install"
  exit 1
fi

swift build -c release
BIN="$(swift build -c release --show-bin-path)/DragWheel"

APP="build/DragWheel.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/DragWheel"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  pkill -x DragWheel 2>/dev/null || true
  rm -rf /Applications/DragWheel.app
  cp -R "$APP" /Applications/
  open /Applications/DragWheel.app
  echo "Installed to /Applications and launched."
fi
