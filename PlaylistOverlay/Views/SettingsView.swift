import SwiftUI

/// Settings window view for configuring app preferences.
///
/// Provides tabs for:
/// - **General**: Enable/disable desktop and floating overlays
/// - **Appearance**: Customize overlay appearance
/// - **Sources**: Toggle Spotify and Apple Music detection
/// - **About**: App information and GitHub link
struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            sourcesTab
                .tabItem {
                    Label("Sources", systemImage: "music.note.list")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
        .padding()
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section {
                Toggle("Show desktop background overlay", isOn: $appState.wallpaperEnabled)
                Toggle("Show floating overlay", isOn: $appState.overlayEnabled)

                // Note: LaunchAtLogin requires the package to be added
                // Toggle("Launch at login", isOn: LaunchAtLogin.$isEnabled)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Appearance Tab

    private var appearanceTab: some View {
        Form {
            Section("Desktop Overlay Style") {
                Toggle("Show song and artist text", isOn: $appState.wallpaperTextOverlay)

                Text("The desktop overlay displays album art with a blurred background behind all windows.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Sources Tab

    private var sourcesTab: some View {
        Form {
            Section("Music Sources") {
                Toggle(isOn: appState.spotifyEnabled) {
                    HStack {
                        Image(systemName: "music.note")
                        Text("Spotify")
                    }
                }

                Toggle(isOn: appState.appleMusicEnabled) {
                    HStack {
                        Image(systemName: "music.quarternote.3")
                        Text("Apple Music")
                    }
                }
            }

            Section {
                Text("Only the selected sources will be monitored for music playback.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.tv")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Playlist Overlay")
                .font(.title)
                .fontWeight(.semibold)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Dynamic album art overlay for macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Link("View on GitHub", destination: URL(string: "https://github.com/alejmed/playlist-mac-overlay")!)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
