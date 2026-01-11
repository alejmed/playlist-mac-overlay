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
                showTextOverlay: showTextOverlay,
                showMediaControls: false,
                onPrevious: {},
                onPlayPause: {},
                onNext: {}
            )
        )
        self.contentView = contentView
        self.ignoresMouseEvents = true
    }

    /// Updates the overlay with new track information and media control actions
    func updateContent(with nowPlaying: NowPlaying, showTextOverlay: Bool, showMediaControls: Bool, onPrevious: @escaping () -> Void, onPlayPause: @escaping () -> Void, onNext: @escaping () -> Void) {
        let contentView = NSHostingView(
            rootView: DesktopOverlayContentView(
                nowPlaying: nowPlaying,
                showTextOverlay: showTextOverlay,
                showMediaControls: showMediaControls,
                onPrevious: onPrevious,
                onPlayPause: onPlayPause,
                onNext: onNext
            )
        )
        self.contentView = contentView
        self.ignoresMouseEvents = !showMediaControls
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
    let showMediaControls: Bool
    let onPrevious: (() -> Void)?
    let onPlayPause: (() -> Void)?
    let onNext: (() -> Void)?

    var body: some View {
        ZStack {
            AlbumArtView(
                nowPlaying: nowPlaying,
                showTrackInfo: showTextOverlay,
                blurRadius: 30
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            .allowsHitTesting(false)

            if showMediaControls {
                VStack {
                    Spacer()
                    
                    MediaControlsView(
                        nowPlaying: nowPlaying,
                        onPrevious: onPrevious ?? {},
                        onPlayPause: onPlayPause ?? {},
                        onNext: onNext ?? {}
                    )
                    .padding(.bottom, 40)
                }
                .allowsHitTesting(true)
            }
        }
    }
}

/// Minimal media controls view for desktop overlay
struct MediaControlsView: View {
    let nowPlaying: NowPlaying
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onPrevious) {
                Image(systemName: "backward.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
            .buttonStyle(.plain)
            
            Button(action: onPlayPause) {
                Image(systemName: nowPlaying.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            
            Button(action: onNext) {
                Image(systemName: "forward.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .opacity(isHovered ? 1.0 : 0.8)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
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

    /// Shows the overlay with the given track and media controls
    func show(with nowPlaying: NowPlaying, showTextOverlay: Bool, showMediaControls: Bool, onPrevious: @escaping () -> Void, onPlayPause: @escaping () -> Void, onNext: @escaping () -> Void) {
        if window == nil {
            window = DesktopOverlayWindow()
        }

        window?.updateContent(with: nowPlaying, showTextOverlay: showTextOverlay, showMediaControls: showMediaControls, onPrevious: onPrevious, onPlayPause: onPlayPause, onNext: onNext)
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

    /// Updates the content if visible with media controls
    func updateContent(_ nowPlaying: NowPlaying, showTextOverlay: Bool, showMediaControls: Bool, onPrevious: @escaping () -> Void, onPlayPause: @escaping () -> Void, onNext: @escaping () -> Void) {
        guard isVisible, let window = window else { return }
        window.updateContent(with: nowPlaying, showTextOverlay: showTextOverlay, showMediaControls: showMediaControls, onPrevious: onPrevious, onPlayPause: onPlayPause, onNext: onNext)
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

