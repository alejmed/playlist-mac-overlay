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

/// Liquid glass media controls with minimalist design
struct MediaControlsView: View {
    let nowPlaying: NowPlaying
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void

    @State private var isHovered = false
    @State private var hoveredButton: String? = nil

    var body: some View {
        HStack(spacing: 20) {
            // Previous button
            LiquidGlassButton(
                systemName: "backward.fill",
                size: 20,
                isHovered: hoveredButton == "previous"
            ) {
                onPrevious()
            }
            .onHover { hovering in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    hoveredButton = hovering ? "previous" : nil
                }
            }

            // Play/Pause button (larger)
            LiquidGlassButton(
                systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill",
                size: 26,
                isHovered: hoveredButton == "play"
            ) {
                onPlayPause()
            }
            .onHover { hovering in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    hoveredButton = hovering ? "play" : nil
                }
            }

            // Next button
            LiquidGlassButton(
                systemName: "forward.fill",
                size: 20,
                isHovered: hoveredButton == "next"
            ) {
                onNext()
            }
            .onHover { hovering in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    hoveredButton = hovering ? "next" : nil
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            LiquidGlassCapsule()
        )
        .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 12)
        .shadow(color: .white.opacity(isHovered ? 0.15 : 0), radius: isHovered ? 20 : 0, x: 0, y: 0)
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.68), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

/// Liquid glass capsule background
struct LiquidGlassCapsule: View {
    var body: some View {
        ZStack {
            // Base ultra-thin material
            Capsule()
                .fill(.ultraThinMaterial)

            // Liquid glass gradient overlay
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)

            // Dark tint for depth
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Shimmering border
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )

            // Inner highlight for depth
            Capsule()
                .inset(by: 1.5)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
        }
    }
}

/// Individual liquid glass control button
struct LiquidGlassButton: View {
    let systemName: String
    let size: CGFloat
    let isHovered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 1.0 : 0.95),
                            Color.white.opacity(isHovered ? 0.95 : 0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 44, height: 44)
                .background(
                    ZStack {
                        // Hover glow
                        if isHovered {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 22
                                    )
                                )
                        }
                    }
                )
                .shadow(color: .black.opacity(isHovered ? 0.3 : 0.2), radius: 3, x: 0, y: 1)
                .scaleEffect(isHovered ? 1.15 : 1.0)
        }
        .buttonStyle(.plain)
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

