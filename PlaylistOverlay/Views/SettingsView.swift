import SwiftUI

/// Settings window view for configuring app preferences.
///
/// Provides tabs for:
/// - **General**: Enable/disable features, restore wallpaper, clear cache
/// - **Appearance**: Adjust blur intensity and album art size
/// - **Sources**: Toggle Spotify and Apple Music detection
/// - **About**: App information and GitHub link
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("blurRadius") private var blurRadius: Double = 60
    @AppStorage("albumArtSize") private var albumArtSize: Double = 0.4
    @AppStorage("transitionDuration") private var transitionDuration: Double = 0.8

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
                Toggle("Update wallpaper automatically", isOn: $appState.wallpaperEnabled)
                Toggle("Show floating overlay", isOn: $appState.overlayEnabled)

                // Note: LaunchAtLogin requires the package to be added
                // Toggle("Launch at login", isOn: LaunchAtLogin.$isEnabled)
            }

            Section {
                Button("Restore Original Wallpaper") {
                    Task {
                        try? await appState.wallpaperService.restoreOriginalWallpaper()
                    }
                }

                Button("Clear Image Cache") {
                    appState.wallpaperService.clearCache()
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Appearance Tab

    private var appearanceTab: some View {
        Form {
            Section("Wallpaper Style") {
                VStack(alignment: .leading) {
                    Text("Blur Intensity: \(Int(blurRadius))")
                    Slider(value: $blurRadius, in: 20...100, step: 5) {
                        Text("Blur")
                    }
                    .onChange(of: blurRadius) { newValue in
                        appState.wallpaperService.setBlurRadius(CGFloat(newValue))
                    }
                }

                VStack(alignment: .leading) {
                    Text("Album Art Size: \(Int(albumArtSize * 100))%")
                    Slider(value: $albumArtSize, in: 0.2...0.7, step: 0.05) {
                        Text("Size")
                    }
                    .onChange(of: albumArtSize) { newValue in
                        appState.wallpaperService.setAlbumArtSizeRatio(CGFloat(newValue))
                    }
                }

                VStack(alignment: .leading) {
                    Text("Transition Speed: \(String(format: "%.1f", transitionDuration))s")
                    Slider(value: $transitionDuration, in: 0.3...2.0, step: 0.1) {
                        Text("Speed")
                    }
                    .onChange(of: transitionDuration) { newValue in
                        appState.wallpaperService.setTransitionDuration(newValue)
                    }
                    Text("How long it takes to fade between wallpapers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
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

            Text("Dynamic album art wallpapers for macOS")
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
