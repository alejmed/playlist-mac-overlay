# Playlist Overlay

A sleek macOS menu bar app that dynamically displays album art as your desktop wallpaper based on currently playing Spotify or Apple Music tracks.

![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Dynamic Wallpaper**: Automatically updates your desktop wallpaper with the currently playing album art
- **Beautiful Blur Effect**: Album art is displayed centered with an artistic blurred background
- **Dual Mode Support**:
  - Replace desktop wallpaper with generated album art image
  - Optional floating overlay window that stays on top
- **Multi-Player Support**: Works with both Spotify and Apple Music
- **Multi-Display Ready**: Supports multiple monitors
- **Smooth Transitions**: Elegant transitions between songs
- **Menu Bar App**: Minimal, non-intrusive interface that lives in your menu bar
- **Lightweight**: Target <1% CPU usage with efficient image processing

## Screenshots

_Coming soon_

## Requirements

- macOS 13.0 (Ventura) or later
- Spotify and/or Apple Music installed
- Xcode 15.0+ (for development)

## Installation

### Download Pre-built App
_Coming soon - releases will be available on GitHub Releases_

### Build from Source

1. Clone the repository:
```bash
git clone https://github.com/alejmed/playlist-mac-overlay.git
cd playlist-mac-overlay
```

2. Install XcodeGen (if not already installed):
```bash
brew install xcodegen
```

3. Generate the Xcode project:
```bash
xcodegen generate
```

4. Open the project:
```bash
open PlaylistOverlay.xcodeproj
```

5. Build and run the project in Xcode (⌘R)

## Usage

1. Launch the app - you'll see a music note icon in your menu bar
2. Play a song in Spotify or Apple Music
3. Your desktop wallpaper will automatically update with the album art
4. Click the menu bar icon to:
   - See current track info
   - Toggle overlay mode
   - Access settings
   - Enable/disable the app

### Settings

- **Display Mode**: Choose between wallpaper mode, overlay mode, or both
- **Player Selection**: Enable/disable Spotify or Apple Music detection
- **Blur Intensity**: Adjust the background blur effect
- **Launch at Login**: Start the app automatically when you log in

## How It Works

### Media Detection
- **Spotify**: Uses `DistributedNotificationCenter` to listen for real-time playback notifications
- **Apple Music**: Polls AppleScript every 2-3 seconds to check current track

### Image Processing
- Fetches album artwork from the media player
- Applies Core Image's `CIGaussianBlur` to create the background
- Composites centered sharp album art over the blurred background
- Generates images optimized for your screen resolution

### Wallpaper Setting
- Uses `NSWorkspace.shared.setDesktopImageURL()` API
- Handles multiple displays via `NSScreen.screens`
- Creates unique temporary files to work around macOS caching issues

## Architecture

```
PlaylistOverlay/
├── App/                      # App entry point and state management
│   ├── PlaylistOverlayApp.swift
│   └── AppState.swift
├── Models/                   # Data models
│   ├── NowPlaying.swift
│   └── PlayerSource.swift
├── Services/                 # Core business logic
│   ├── MediaDetection/
│   │   ├── MediaDetectionService.swift
│   │   ├── SpotifyDetector.swift
│   │   └── AppleMusicDetector.swift
│   └── WallpaperService.swift
├── Views/                    # SwiftUI views
│   ├── MenuBarView.swift
│   ├── OverlayWindow.swift
│   ├── AlbumArtView.swift
│   └── SettingsView.swift
└── Utilities/                # Helper classes
    ├── ImageProcessor.swift
    └── AppleScriptRunner.swift
```

## Development

### Project Setup

This project uses XcodeGen to manage the Xcode project file. To modify the project structure:

1. Edit `project.yml`
2. Regenerate the project:
```bash
xcodegen generate
```

### Testing

Run tests in Xcode:
```bash
xcodebuild test -scheme PlaylistOverlay -destination 'platform=macOS'
```

### Claude Agents

This project includes specialized Claude Code agent files for different areas:

- `.claude/agents/media-detection.md` - Media detection logic
- `.claude/agents/wallpaper-engine.md` - Image processing and wallpaper APIs
- `.claude/agents/ui-components.md` - SwiftUI views and UI
- `.claude/agents/testing.md` - Test implementation

## Permissions

The app requires the following permissions:

- **AppleEvents**: To communicate with Spotify and Apple Music via AppleScript
- **File Access**: To save temporary wallpaper images

On first run, macOS will prompt you to grant these permissions in System Preferences > Security & Privacy.

## Performance

Target performance metrics:
- CPU usage: <1% during normal operation
- Image generation: <500ms
- Memory footprint: <50MB
- Minimal battery impact with smart pausing

## Roadmap

- [ ] Custom wallpaper templates/layouts
- [ ] Animation effects between transitions
- [ ] Support for additional music players
- [ ] Keyboard shortcuts
- [ ] More blur/effect options
- [ ] Playlist-based wallpaper rotation
- [ ] Widget showing current track

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Known Issues

- macOS Sonoma+ has a regression where `fillColor` option no longer works for wallpapers
- Wallpaper changes don't apply behind active full-screen apps (system limitation)
- Changes only apply to active Space/Desktop (system limitation)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [Backdrop](https://cindori.com/backdrop) for desktop wallpaper apps
- Built with pure Apple frameworks (no external dependencies)
- Uses research from [sindresorhus/macos-wallpaper](https://github.com/sindresorhus/macos-wallpaper)

## Support

If you encounter any issues or have questions:
- Open an issue on [GitHub Issues](https://github.com/alejmed/playlist-mac-overlay/issues)
- Check existing issues for similar problems

---

Made with ♫ for music lovers
