import AppKit
import Combine
import Foundation

/// Manages setting and updating the macOS desktop wallpaper based on album art.
///
/// This service handles:
/// - Generating wallpaper images from album artwork using `ImageProcessor`
/// - Setting wallpapers on all connected displays via `NSWorkspace` API
/// - Caching generated images to avoid redundant processing
/// - Saving and restoring original wallpapers
/// - Managing temporary wallpaper files in Application Support
///
/// The service works around macOS's wallpaper caching by generating unique filenames
/// for each wallpaper update, ensuring the system detects the change.
///
/// ## Usage
/// ```swift
/// let service = WallpaperService()
/// try await service.updateWallpaper(for: nowPlaying)
/// try await service.restoreOriginalWallpaper() // when done
/// ```
final class WallpaperService: ObservableObject {

    // MARK: - Published Properties

    /// Whether the service is actively managing the wallpaper
    @Published private(set) var isActive = false

    /// The last error encountered, if any
    @Published private(set) var lastError: Error?

    // MARK: - Private Properties

    /// Image processor for generating blurred wallpaper images
    private let imageProcessor = ImageProcessor()

    /// File manager for handling wallpaper file operations
    private let fileManager = FileManager.default

    /// Transition service for smooth wallpaper changes
    private let transitionService = TransitionService()

    /// Cache mapping track cache keys to generated wallpaper file URLs
    private var imageCache: [String: URL] = [:]

    /// Whether to use smooth transitions (default: true)
    var enableTransitions = true

    /// Directory for storing generated wallpapers in Application Support.
    ///
    /// Located at: `~/Library/Application Support/PlaylistOverlay/Wallpapers/`
    ///
    /// The directory is created automatically if it doesn't exist.
    private lazy var wallpaperDirectory: URL = {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PlaylistOverlay/Wallpapers", isDirectory: true)

        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)

        return dir
    }()

    /// Original wallpaper URLs before the app modified them, keyed by screen.
    ///
    /// Used to restore the user's original wallpapers when the app is disabled
    /// or when `restoreOriginalWallpaper()` is called.
    private var originalWallpaper: [NSScreen: URL] = [:]

    // MARK: - Initialization

    /// Initializes the wallpaper service and saves the current wallpapers for restoration
    init() {
        saveOriginalWallpapers()
    }

    // MARK: - Private Methods

    /// Saves the current wallpaper for each screen so it can be restored later.
    ///
    /// This is called once during initialization to capture the user's original
    /// wallpapers before the app makes any modifications.
    private func saveOriginalWallpapers() {
        for screen in NSScreen.screens {
            if let url = NSWorkspace.shared.desktopImageURL(for: screen) {
                originalWallpaper[screen] = url
            }
        }
    }

    // MARK: - Public Methods

    /// Updates the wallpaper with the given track's album art.
    ///
    /// This method:
    /// 1. Checks the cache for a previously generated wallpaper
    /// 2. If not cached, generates a new wallpaper image with blurred background
    /// 3. Saves the image to a file
    /// 4. Sets the wallpaper on all connected displays
    /// 5. Caches the result for future use
    ///
    /// - Parameter track: The currently playing track with artwork
    /// - Throws: `WallpaperError` if artwork is missing, screen is unavailable,
    ///           image generation fails, or wallpaper setting fails
    func updateWallpaper(for track: NowPlaying) async throws {
        guard let artwork = track.artworkImage else {
            throw WallpaperError.noArtwork
        }

        // Check cache first
        if let cachedURL = imageCache[track.cacheKey],
           fileManager.fileExists(atPath: cachedURL.path),
           let cachedImage = NSImage(contentsOf: cachedURL) {
            try await setWallpaperWithTransition(url: cachedURL, image: cachedImage)
            return
        }

        // Get the main screen size
        guard let mainScreen = NSScreen.main else {
            throw WallpaperError.noScreen
        }

        let screenSize = mainScreen.frame.size

        // Generate the wallpaper image
        guard let wallpaperImage = imageProcessor.createWallpaperImage(from: artwork, for: screenSize, title: track.title, artist: track.artist) else {
            throw WallpaperError.imageGenerationFailed
        }

        // Save to file with unique name
        let filename = "\(track.cacheKey.hash).png"
        let fileURL = wallpaperDirectory.appendingPathComponent(filename)

        try imageProcessor.saveImage(wallpaperImage, to: fileURL)

        // Cache the URL
        imageCache[track.cacheKey] = fileURL

        // Set the wallpaper with smooth transition
        try await setWallpaperWithTransition(url: fileURL, image: wallpaperImage)

        await MainActor.run {
            self.isActive = true
        }
    }

    /// Sets the wallpaper with a smooth transition effect
    private func setWallpaperWithTransition(url: URL, image: NSImage) async throws {
        if enableTransitions {
            // Start the visual transition overlay
            async let transitionTask: Void = transitionService.performTransition(to: image)

            // Update the actual wallpaper at the midpoint of the transition
            // This is when the new image is at ~50% opacity for smoothest crossfade
            let midpoint = transitionService.transitionDuration / 2.0
            try await Task.sleep(nanoseconds: UInt64(midpoint * 1_000_000_000))
            try await setWallpaper(url: url)

            // Wait for transition to complete
            await transitionTask
        } else {
            // No transition, just set directly
            try await setWallpaper(url: url)
        }
    }

    /// Sets the wallpaper on all screens
    private func setWallpaper(url: URL) async throws {
        let workspace = NSWorkspace.shared

        for screen in NSScreen.screens {
            do {
                try workspace.setDesktopImageURL(url, for: screen, options: [:])
            } catch {
                await MainActor.run {
                    self.lastError = error
                }
                throw WallpaperError.settingFailed(error)
            }
        }

        // Small delay to ensure wallpaper is applied
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
    }

    /// Restores the original wallpaper
    func restoreOriginalWallpaper() async throws {
        let workspace = NSWorkspace.shared

        for (screen, url) in originalWallpaper {
            do {
                try workspace.setDesktopImageURL(url, for: screen, options: [:])
            } catch {
                throw WallpaperError.settingFailed(error)
            }
        }

        await MainActor.run {
            self.isActive = false
        }
    }

    /// Clears the image cache and removes generated files
    func clearCache() {
        imageCache.removeAll()

        guard let contents = try? fileManager.contentsOfDirectory(at: wallpaperDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }

    /// Sets the blur radius for generated wallpapers
    func setBlurRadius(_ radius: CGFloat) {
        imageProcessor.blurRadius = radius
        // Clear cache to regenerate with new settings
        imageCache.removeAll()
    }

    /// Sets the album art size ratio
    func setAlbumArtSizeRatio(_ ratio: CGFloat) {
        imageProcessor.albumArtSizeRatio = ratio
        imageCache.removeAll()
    }

    /// Sets the transition duration for wallpaper changes
    /// - Parameter duration: Duration in seconds (0.3 - 2.0)
    func setTransitionDuration(_ duration: TimeInterval) {
        transitionService.transitionDuration = min(max(duration, 0.3), 2.0)
    }

    /// Sets whether to show text overlay on wallpapers
    func setTextOverlayEnabled(_ enabled: Bool) {
        imageProcessor.showTextOverlay = enabled
        // Clear cache to regenerate with new settings
        imageCache.removeAll()
    }

    // MARK: - Error Types

    /// Errors that can occur during wallpaper operations
    enum WallpaperError: Error, LocalizedError {

        /// The track has no artwork available
        case noArtwork

        /// No screen could be detected
        case noScreen

        /// Failed to generate the wallpaper image
        case imageGenerationFailed

        /// Failed to set the wallpaper (includes underlying error)
        case settingFailed(Error)

        /// Human-readable error descriptions
        var errorDescription: String? {
            switch self {
            case .noArtwork:
                return "No artwork available for the current track"
            case .noScreen:
                return "Could not detect main screen"
            case .imageGenerationFailed:
                return "Failed to generate wallpaper image"
            case .settingFailed(let error):
                return "Failed to set wallpaper: \(error.localizedDescription)"
            }
        }
    }
}
