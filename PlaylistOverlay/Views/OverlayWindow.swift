import AppKit
import SwiftUI

/// A floating panel for displaying album art overlay
class OverlayPanel: NSPanel {

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 400),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )

        self.contentView = contentView
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true

        // Set minimum size
        self.minSize = NSSize(width: 200, height: 250)

        // Center on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - frame.width / 2
            let y = screenFrame.midY - frame.height / 2
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return false
    }
}

/// SwiftUI view for the overlay content
struct OverlayContentView: View {
    let nowPlaying: NowPlaying
    @State private var isHovered = false

    var body: some View {
        ZStack {
            // Main album art view
            AlbumArtView(nowPlaying: nowPlaying, showTrackInfo: true, blurRadius: 30)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // Close button (shown on hover)
            if isHovered {
                VStack {
                    HStack {
                        Spacer()

                        Button(action: {
                            NotificationCenter.default.post(name: .hideOverlay, object: nil)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .padding(12)
                    }
                    Spacer()
                }
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

/// Manages the overlay window lifecycle
class OverlayWindowController: ObservableObject {
    private var panel: OverlayPanel?
    @Published var isVisible = false

    func show(with nowPlaying: NowPlaying) {
        if panel == nil {
            let contentView = NSHostingView(rootView: OverlayContentView(nowPlaying: nowPlaying))
            panel = OverlayPanel(contentView: contentView)
        } else {
            // Update content
            let contentView = NSHostingView(rootView: OverlayContentView(nowPlaying: nowPlaying))
            panel?.contentView = contentView
        }

        panel?.orderFront(nil)
        isVisible = true
    }

    func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }

    func toggle(with nowPlaying: NowPlaying?) {
        if isVisible {
            hide()
        } else if let nowPlaying = nowPlaying {
            show(with: nowPlaying)
        }
    }

    func updateContent(_ nowPlaying: NowPlaying) {
        guard isVisible else { return }

        let contentView = NSHostingView(rootView: OverlayContentView(nowPlaying: nowPlaying))
        panel?.contentView = contentView
    }
}

// Notification extension for overlay visibility
extension Notification.Name {
    static let hideOverlay = Notification.Name("hideOverlay")
    static let showOverlay = Notification.Name("showOverlay")
}
