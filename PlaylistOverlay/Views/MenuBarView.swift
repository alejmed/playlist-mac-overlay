import SwiftUI

/// Main menu bar popover view
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Current track section
            if let nowPlaying = appState.mediaService.currentlyPlaying {
                CompactAlbumArtView(nowPlaying: nowPlaying)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)

                Divider()
            } else {
                noMusicView
                    .padding()

                Divider()
            }

            // Controls section
            VStack(spacing: 4) {
                // Wallpaper toggle
                Toggle(isOn: $appState.wallpaperEnabled) {
                    Label("Update Wallpaper", systemImage: "photo.fill")
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                // Overlay toggle
                Toggle(isOn: $appState.overlayEnabled) {
                    Label("Show Overlay", systemImage: "rectangle.on.rectangle")
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }

            Divider()

            // Source selection
            VStack(alignment: .leading, spacing: 4) {
                Text("Sources")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                Toggle(isOn: $appState.mediaService.spotifyEnabled) {
                    Label("Spotify", systemImage: "music.note")
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

                Toggle(isOn: $appState.mediaService.appleMusicEnabled) {
                    Label("Apple Music", systemImage: "music.quarternote.3")
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }

            Divider()

            // Footer actions
            HStack {
                Button("Settings...") {
                    appState.showSettings()
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
        .frame(width: 280)
    }

    private var noMusicView: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No music playing")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Play a song in Spotify or Apple Music")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppState())
}
