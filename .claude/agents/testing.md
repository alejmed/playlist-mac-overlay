# Testing Agent

This agent handles all testing for the PlaylistOverlay app.

## Responsibilities

- Writing unit tests for models
- Writing unit tests for services
- Writing integration tests
- Creating mock objects for testing
- Documenting manual testing procedures

## Test Structure

```
Tests/
└── PlaylistOverlayTests/
    ├── Models/
    │   ├── NowPlayingTests.swift
    │   └── PlayerSourceTests.swift
    ├── Services/
    │   ├── SpotifyDetectorTests.swift
    │   ├── AppleMusicDetectorTests.swift
    │   ├── ImageProcessorTests.swift
    │   └── WallpaperServiceTests.swift
    └── Mocks/
        ├── MockMediaDetector.swift
        └── MockImageProcessor.swift
```

## Unit Tests

### NowPlaying Model
- Test initialization with all fields
- Test Equatable conformance
- Test with nil artwork

### Media Detection
- Test notification parsing for Spotify
- Test AppleScript result parsing
- Test error handling for unavailable apps

### Image Processor
- Test blur effect generation
- Test composite image creation
- Test various input sizes

## Integration Tests

### Media Detection Flow
1. Mock notification received
2. Verify NowPlaying object created
3. Verify artwork fetched
4. Verify wallpaper service called

### End-to-End Flow
1. Simulate song change
2. Verify image generated
3. Verify wallpaper updated

## Manual Testing Checklist

### Spotify Integration
- [ ] App detects Spotify is running
- [ ] Current track info displays correctly
- [ ] Album art loads
- [ ] Song changes detected in real-time
- [ ] Pause/play state tracked

### Apple Music Integration
- [ ] App detects Music app is running
- [ ] Current track info displays correctly
- [ ] Album art loads
- [ ] Song changes detected within 3 seconds
- [ ] Pause/play state tracked

### Wallpaper
- [ ] Wallpaper updates on song change
- [ ] Blur effect renders correctly
- [ ] Album art centered properly
- [ ] Multi-display support works
- [ ] Transitions appear smooth

### UI
- [ ] Menu bar icon visible
- [ ] Popover opens/closes correctly
- [ ] Overlay window appears
- [ ] Overlay is draggable
- [ ] Settings persist after restart

### Performance
- [ ] CPU usage under 1%
- [ ] No memory leaks
- [ ] Image generation under 500ms
- [ ] App launches quickly

## Files to Create

- `Tests/PlaylistOverlayTests/Models/NowPlayingTests.swift`
- `Tests/PlaylistOverlayTests/Services/SpotifyDetectorTests.swift`
- `Tests/PlaylistOverlayTests/Services/AppleMusicDetectorTests.swift`
- `Tests/PlaylistOverlayTests/Services/ImageProcessorTests.swift`
- `Tests/PlaylistOverlayTests/Mocks/MockMediaDetector.swift`

## Testing Commands

```bash
# Run all tests
xcodebuild test -scheme PlaylistOverlay -destination 'platform=macOS'

# Run specific test
xcodebuild test -scheme PlaylistOverlay -destination 'platform=macOS' -only-testing:PlaylistOverlayTests/NowPlayingTests
```
