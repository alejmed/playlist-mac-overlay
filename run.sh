#!/bin/bash
# Build and run Playlist Overlay

set -e

echo "🎵 Building and running Playlist Overlay..."

# Build the project
xcodebuild \
    -project PlaylistOverlay.xcodeproj \
    -scheme PlaylistOverlay \
    -configuration Debug \
    -derivedDataPath build \
    build \
    2>&1 | grep -E "Build Succeeded|error:|warning:" || true

APP_PATH="build/Build/Products/Debug/Playlist Overlay.app"

if [ -d "$APP_PATH" ]; then
    echo "✅ Build complete!"
    echo "🚀 Launching app..."
    open "$APP_PATH"
else
    echo "❌ Build failed - app not found at $APP_PATH"
    exit 1
fi
