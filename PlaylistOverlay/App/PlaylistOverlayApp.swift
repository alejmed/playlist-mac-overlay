import SwiftUI

/// The main app entry point for Playlist Overlay.
///
/// This app creates a menu bar-only application (no dock icon) that displays
/// album art as dynamic wallpaper for Spotify and Apple Music.
///
/// ## Architecture
/// - **MenuBarExtra**: The primary UI, accessed via the menu bar icon
/// - **Settings Window**: Accessible from the menu bar for configuration
/// - **AppState**: Central state management via `@StateObject`
///
/// The app uses SwiftUI's `MenuBarExtra` (macOS 13+) to create a native menu bar
/// experience without appearing in the Dock (controlled via `LSUIElement` in Info.plist).
@main
struct PlaylistOverlayApp: App {

    /// Central application state, shared across all views via `@EnvironmentObject`
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menu bar extra (macOS 13+)
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Label("Playlist Overlay", systemImage: menuBarIcon)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }

    /// Dynamic menu bar icon based on playback state
    private var menuBarIcon: String {
        if appState.mediaService.currentlyPlaying?.isPlaying == true {
            return "music.note.tv.fill"
        }
        return "music.note.tv"
    }
}
