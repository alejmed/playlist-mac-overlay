# UI Components Agent

This agent handles all SwiftUI views and UI components for the PlaylistOverlay app.

## Responsibilities

- Implementing `MenuBarView.swift` for the menu bar interface
- Implementing `OverlayWindow.swift` for the floating album art panel
- Implementing `AlbumArtView.swift` for the blurred album art display
- Implementing `SettingsView.swift` for user preferences
- Managing the app delegate and menu bar setup

## Key Technical Details

### Menu Bar App
- Use `MenuBarExtra` (macOS 13+) for modern SwiftUI approach
- Show app icon in menu bar
- Popover with current track info and controls

### Floating Overlay Window
- Use `NSPanel` with specific configuration:
  - `.nonactivatingPanel` style (doesn't steal focus)
  - `.floating` window level
  - Draggable and optionally resizable
  - Transparent background with vibrancy

### SwiftUI Patterns

**Menu Bar:**
```swift
@main
struct PlaylistOverlayApp: App {
    var body: some Scene {
        MenuBarExtra("Playlist Overlay", systemImage: "music.note") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Album Art View:**
```swift
struct AlbumArtView: View {
    let artwork: NSImage

    var body: some View {
        ZStack {
            Image(nsImage: artwork)
                .resizable()
                .blur(radius: 50)

            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(12)
                .shadow(radius: 20)
        }
    }
}
```

**Floating Panel:**
```swift
class FloatingPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
    }
}
```

## Files to Modify

- `PlaylistOverlay/App/PlaylistOverlayApp.swift`
- `PlaylistOverlay/App/AppDelegate.swift`
- `PlaylistOverlay/Views/MenuBarView.swift`
- `PlaylistOverlay/Views/OverlayWindow.swift`
- `PlaylistOverlay/Views/AlbumArtView.swift`
- `PlaylistOverlay/Views/SettingsView.swift`

## Design Guidelines

- Use SF Symbols for icons
- Support dark and light mode
- Use system materials for glassmorphism
- Keep UI minimal and unobtrusive
- Smooth animations for state changes

## Testing

- Test menu bar icon appears correctly
- Test popover opens and closes
- Test overlay window positioning
- Test overlay dragging
- Test settings persistence
- Test dark/light mode switching
