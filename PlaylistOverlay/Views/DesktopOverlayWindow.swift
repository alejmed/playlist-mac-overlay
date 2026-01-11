import AppKit
import SwiftUI

/// A fullscreen desktop overlay window that sits between the wallpaper and regular apps.
///
/// This window:
/// - Covers the entire screen at desktop level
/// - Displays blurred album art as a background
/// - Ignores mouse events (clicks pass through)
/// - Automatically cleans up when the app quits
/// - Does NOT modify the actual wallpaper
class DesktopOverlayWindow: NSWindow {

    init() {
        // Create a borderless, fullscreen window
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Desktop-level positioning: above wallpaper, below apps
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)

        // Make it fullscreen on all displays
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Transparent and non-interactive
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.hasShadow = false

        // Don't show in window lists or Cmd+Tab
        self.isExcludedFromWindowsMenu = true

        // Cover all screens
        setupForAllScreens()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Positions the window to cover all connected displays
    private func setupForAllScreens() {
        guard let mainScreen = NSScreen.main else { return }

        // For now, just cover the main screen
        // Future enhancement: create multiple windows for multi-display
        let screenFrame = mainScreen.frame
        self.setFrame(screenFrame, display: true)
    }

    /// Updates the overlay with new track information
    func updateContent(with nowPlaying: NowPlaying, showTextOverlay: Bool) {
        let contentView = NSHostingView(
            rootView: DesktopOverlayContentView(
                nowPlaying: nowPlaying,
                showTextOverlay: showTextOverlay
            )
        )
        self.contentView = contentView
    }

    /// Shows the overlay
    func show() {
        self.orderFront(nil)
    }

    /// Hides the overlay
    func hide() {
        self.orderOut(nil)
    }
}

/// SwiftUI view for the desktop overlay content
struct DesktopOverlayContentView: View {
    let nowPlaying: NowPlaying
    let showTextOverlay: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Use the existing AlbumArtView which already handles blurred backgrounds
                AlbumArtView(
                    nowPlaying: nowPlaying,
                    showTrackInfo: showTextOverlay,
                    blurRadius: 30
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}

/// Manages the desktop overlay lifecycle
@MainActor
class DesktopOverlayController: ObservableObject {
    private var window: DesktopOverlayWindow?
    @Published var isVisible = false

    /// Shows the overlay with the given track
    func show(with nowPlaying: NowPlaying, showTextOverlay: Bool) {
        if window == nil {
            window = DesktopOverlayWindow()
        }

        window?.updateContent(with: nowPlaying, showTextOverlay: showTextOverlay)
        window?.show()
        isVisible = true
    }

    /// Hides the overlay
    func hide() {
        window?.hide()
        isVisible = false
    }

    /// Updates the content if visible
    func updateContent(_ nowPlaying: NowPlaying, showTextOverlay: Bool) {
        guard isVisible, let window = window else { return }
        window.updateContent(with: nowPlaying, showTextOverlay: showTextOverlay)
    }

    /// Toggles overlay visibility
    func toggle(with nowPlaying: NowPlaying?, showTextOverlay: Bool) {
        if isVisible {
            hide()
        } else if let nowPlaying = nowPlaying {
            show(with: nowPlaying, showTextOverlay: showTextOverlay)
        }
    }
}
