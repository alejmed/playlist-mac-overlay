#!/bin/bash
# Build script for Playlist Overlay

set -e

echo "🎵 Building Playlist Overlay..."

# Build the project
xcodebuild \
    -project PlaylistOverlay.xcodeproj \
    -scheme PlaylistOverlay \
    -configuration Debug \
    -derivedDataPath build \
    build

echo "✅ Build complete!"
echo "📦 App location: build/Build/Products/Debug/Playlist Overlay.app"
echo ""
echo "To run the app:"
echo "  open \"build/Build/Products/Debug/Playlist Overlay.app\""
