import Combine
import SwiftUI
import AppKit

/// Central application state manager that coordinates all app services and user preferences.
///
/// This class serves as the single source of truth for the application, managing:
/// - Media detection from Spotify and Apple Music
/// - Wallpaper generation and updates
/// - Floating overlay window visibility
/// - User preferences persistence via `@AppStorage`
/// - Reactive bindings between services
///
/// All methods run on the `@MainActor` to ensure thread-safe UI updates.
///
/// ## Usage
/// The `AppState` is created once in `PlaylistOverlayApp` and shared across
/// all views via `@EnvironmentObject`:
///
/// ```swift
/// struct SomeView: View {
///     @EnvironmentObject var appState: AppState
///
///     var body: some View {
///         Text(appState.mediaService.currentlyPlaying?.title ?? "Nothing playing")
///     }
/// }
/// ```
@MainActor
final class AppState: ObservableObject {

    // MARK: - Services

    /// Service for detecting currently playing media from Spotify and Apple Music
    let mediaService = MediaDetectionService()

    /// Controller for managing the desktop overlay (replaces wallpaper service)
    let desktopOverlayController = DesktopOverlayController()

    /// Controller for managing the floating overlay window
    let overlayController = OverlayWindowController()

    // MARK: - User Preferences

    /// Whether desktop overlay is enabled (persisted via UserDefaults)
    @AppStorage("wallpaperEnabled") var wallpaperEnabled = true {
        didSet {
            if wallpaperEnabled {
                if let nowPlaying = mediaService.currentlyPlaying {
                    desktopOverlayController.show(with: nowPlaying, showTextOverlay: wallpaperTextOverlay)
                }
            } else {
                desktopOverlayController.hide()
            }
        }
    }

    /// Whether to show text overlay on desktop overlay (persisted via UserDefaults)
    @AppStorage("wallpaperTextOverlay") var wallpaperTextOverlay = false {
        didSet {
            if wallpaperEnabled, let nowPlaying = mediaService.currentlyPlaying {
                desktopOverlayController.updateContent(nowPlaying, showTextOverlay: wallpaperTextOverlay)
            }
        }
    }

    /// Whether the floating overlay window is enabled (persisted via UserDefaults)
    @AppStorage("overlayEnabled") var overlayEnabled = false {
        didSet {
            if overlayEnabled {
                if let nowPlaying = mediaService.currentlyPlaying {
                    overlayController.show(with: nowPlaying)
                }
            } else {
                overlayController.hide()
            }
        }
    }

    // MARK: - Computed Properties

    /// Binding to the Spotify enabled state in mediaService
    var spotifyEnabled: Binding<Bool> {
        Binding(
            get: { self.mediaService.spotifyEnabled },
            set: { self.mediaService.spotifyEnabled = $0 }
        )
    }

    /// Binding to the Apple Music enabled state in mediaService
    var appleMusicEnabled: Binding<Bool> {
        Binding(
            get: { self.mediaService.appleMusicEnabled },
            set: { self.mediaService.appleMusicEnabled = $0 }
        )
    }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private var settingsWindow: NSWindow?

    // MARK: - Initialization

    init() {
        setupBindings()
        setupNotifications()
    }

    /// Sets up Combine bindings for reactive updates
    private func setupBindings() {
        // React to track changes
        mediaService.$currentlyPlaying
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] nowPlaying in
                print("📱 [AppState] Track changed: \(nowPlaying?.title ?? "nil") - \(nowPlaying?.artist ?? "nil")")
                Task { @MainActor in
                    await self?.handleTrackChange(nowPlaying)
                }
            }
            .store(in: &cancellables)
    }

    /// Sets up notification observers
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .hideOverlay,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.overlayEnabled = false
        }
    }

    /// Handles track change events
    private func handleTrackChange(_ nowPlaying: NowPlaying?) async {
        print("🎵 [AppState] handleTrackChange called")
        print("   - nowPlaying: \(nowPlaying?.title ?? "nil")")
        print("   - isPlaying: \(nowPlaying?.isPlaying ?? false)")
        print("   - wallpaperEnabled: \(wallpaperEnabled)")
        print("   - hasArtwork: \(nowPlaying?.artworkImage != nil)")

        guard let nowPlaying = nowPlaying, nowPlaying.isPlaying else {
            print("⚠️ [AppState] Not playing or nil, skipping update")
            return
        }

        // Update desktop overlay if enabled
        if wallpaperEnabled {
            print("🖼️ [AppState] Updating desktop overlay...")
            desktopOverlayController.updateContent(nowPlaying, showTextOverlay: wallpaperTextOverlay)
            print("✅ [AppState] Desktop overlay updated successfully!")
        } else {
            print("⏭️ [AppState] Desktop overlay disabled, skipping")
        }

        // Update floating overlay if visible
        if overlayEnabled {
            print("📺 [AppState] Updating floating overlay...")
            overlayController.updateContent(nowPlaying)
        }
    }

    /// Shows the settings window
    func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .environmentObject(self)

            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "Playlist Overlay Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 450, height: 350))
            window.center()

            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
