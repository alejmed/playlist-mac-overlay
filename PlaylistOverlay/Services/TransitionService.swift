import AppKit
import SwiftUI

/// Manages smooth transitions between wallpaper changes using a full-screen overlay.
///
/// Creates a temporary full-screen window that cross-fades between the old and new
/// wallpaper images, providing a smooth visual transition instead of an instant change.
final class TransitionService {

    /// Duration of the fade transition in seconds
    var transitionDuration: TimeInterval = 0.8

    /// The current transition window, if one is active
    private var transitionWindow: NSWindow?

    /// Shows a smooth transition from the current wallpaper to a new image.
    ///
    /// This creates a full-screen overlay window that:
    /// 1. Shows the new image with opacity 0
    /// 2. Fades in the new image (cross-fade effect)
    /// 3. Updates the actual wallpaper behind the overlay (at midpoint)
    /// 4. Fades out and removes the overlay
    ///
    /// - Parameter newImage: The new wallpaper image to transition to
    @MainActor
    func performTransition(to newImage: NSImage) async {
        guard let screen = NSScreen.main else { return }

        // Create transition view controller
        let viewModel = TransitionViewModel(duration: transitionDuration)
        let transitionView = TransitionView(
            image: newImage,
            viewModel: viewModel
        )

        let hostingView = NSHostingView(rootView: transitionView)
        hostingView.frame = screen.frame

        // Create full-screen window
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.contentView = hostingView
        window.backgroundColor = .clear
        window.isOpaque = false
        // Set to desktop level - just above the wallpaper but below all app windows
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        transitionWindow = window
        // Order behind everything - stay at desktop level
        window.orderBack(nil)

        // Wait for fade in to complete, then start fade out
        let fadeInDuration = transitionDuration * 0.6 // 60% of time for fade in
        try? await Task.sleep(nanoseconds: UInt64(fadeInDuration * 1_000_000_000))

        // Start fade out
        await viewModel.fadeOut()

        // Wait for fade out to complete
        let fadeOutDuration = transitionDuration * 0.4 // 40% of time for fade out
        try? await Task.sleep(nanoseconds: UInt64(fadeOutDuration * 1_000_000_000))

        // Close and cleanup
        window.orderOut(nil)
        transitionWindow = nil
    }

    /// Cancels any active transition
    @MainActor
    func cancelTransition() {
        transitionWindow?.orderOut(nil)
        transitionWindow = nil
    }
}

/// View model to control the transition animation state
@MainActor
private class TransitionViewModel: ObservableObject {
    @Published var opacity: Double = 0.0
    let duration: TimeInterval

    init(duration: TimeInterval) {
        self.duration = duration
    }

    func start() {
        // Smooth fade in with custom easing curve
        // Uses a cubic bezier curve for a more natural, fluid transition
        withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: duration * 0.6)) {
            opacity = 1.0
        }
    }

    func fadeOut() {
        // Smooth fade out
        withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: duration * 0.4)) {
            opacity = 0.0
        }
    }
}

/// SwiftUI view that displays the transition animation
private struct TransitionView: View {
    let image: NSImage
    @ObservedObject var viewModel: TransitionViewModel

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(viewModel.opacity)
            .onAppear {
                viewModel.start()
            }
    }
}
