import SwiftUI

@main
struct PlaylistOverlayApp: App {
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
