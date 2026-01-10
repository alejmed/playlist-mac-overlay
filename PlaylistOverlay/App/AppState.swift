import Combine
import SwiftUI

/// Shared application state
@MainActor
final class AppState: ObservableObject {

    // MARK: - Services

    let mediaService = MediaDetectionService()
    let wallpaperService = WallpaperService()
    let overlayController = OverlayWindowController()

    // MARK: - User Preferences

    @AppStorage("wallpaperEnabled") var wallpaperEnabled = true {
        didSet {
            if !wallpaperEnabled {
                Task {
                    try? await wallpaperService.restoreOriginalWallpaper()
                }
            }
        }
    }

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
        guard let nowPlaying = nowPlaying, nowPlaying.isPlaying else {
            return
        }

        // Update wallpaper if enabled
        if wallpaperEnabled {
            do {
                try await wallpaperService.updateWallpaper(for: nowPlaying)
            } catch {
                print("Failed to update wallpaper: \(error)")
            }
        }

        // Update overlay if visible
        if overlayEnabled {
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
