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
        // Get main screen frame first
        let screenFrame = NSScreen.main?.frame ?? .zero

        // Create a borderless, fullscreen window
        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless],
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

        // Ensure frame covers entire screen
        self.setFrame(screenFrame, display: true, animate: false)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }


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
        AlbumArtView(
            nowPlaying: nowPlaying,
            showTrackInfo: showTextOverlay,
            blurRadius: 30
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
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
