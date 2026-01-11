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

/// Enhanced media controls view for desktop overlay with modern design
struct MediaControlsView: View {
    let nowPlaying: NowPlaying
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void

    @State private var isHovered = false
    @State private var hoveredButton: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            // Track info section
            VStack(spacing: 6) {
                Text(nowPlaying.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                Text(nowPlaying.artist)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Control buttons
            HStack(spacing: 24) {
                // Previous button
                ControlButton(
                    systemName: "backward.fill",
                    size: 22,
                    isHovered: hoveredButton == "previous",
                    isPrimary: false
                ) {
                    onPrevious()
                }
                .onHover { hovering in
                    hoveredButton = hovering ? "previous" : nil
                }

                // Play/Pause button (larger, primary)
                ControlButton(
                    systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill",
                    size: 28,
                    isHovered: hoveredButton == "play",
                    isPrimary: true
                ) {
                    onPlayPause()
                }
                .onHover { hovering in
                    hoveredButton = hovering ? "play" : nil
                }

                // Next button
                ControlButton(
                    systemName: "forward.fill",
                    size: 22,
                    isHovered: hoveredButton == "next",
                    isPrimary: false
                ) {
                    onNext()
                }
                .onHover { hovering in
                    hoveredButton = hovering ? "next" : nil
                }
            }
            .padding(.bottom, 20)
        }
        .frame(minWidth: 320)
        .background(
            ZStack {
                // Glassmorphism background with blur
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .opacity(0.9)

                // Dark overlay for contrast
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.5),
                                Color.black.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoveredButton)
        .onHover { isHovered = $0 }
    }
}

/// Individual control button with hover effects
struct ControlButton: View {
    let systemName: String
    let size: CGFloat
    let isHovered: Bool
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isPrimary ? [
                                Color.white.opacity(isHovered ? 0.3 : 0.2),
                                Color.white.opacity(isHovered ? 0.2 : 0.1)
                            ] : [
                                Color.white.opacity(isHovered ? 0.2 : 0.1),
                                Color.white.opacity(isHovered ? 0.1 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isPrimary ? 70 : 56, height: isPrimary ? 70 : 56)

                // Border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.4 : 0.2),
                                Color.white.opacity(isHovered ? 0.2 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 2 : 1.5
                    )
                    .frame(width: isPrimary ? 70 : 56, height: isPrimary ? 70 : 56)

                // Icon
                Image(systemName: systemName)
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .shadow(
                color: isPrimary ? Color.white.opacity(isHovered ? 0.3 : 0) : .clear,
                radius: isHovered ? 15 : 0,
                x: 0,
                y: 0
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
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

