import AppKit
import Combine
import Foundation

/// Manages setting and updating the macOS desktop wallpaper
final class WallpaperService: ObservableObject {

    @Published private(set) var isActive = false
    @Published private(set) var lastError: Error?

    private let imageProcessor = ImageProcessor()
    private let fileManager = FileManager.default
    private var imageCache: [String: URL] = [:]

    /// Directory for storing generated wallpapers
    private lazy var wallpaperDirectory: URL = {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PlaylistOverlay/Wallpapers", isDirectory: true)

        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)

        return dir
    }()

    /// Original wallpaper URL before the app modified it (for restoration)
    private var originalWallpaper: [NSScreen: URL] = [:]

    init() {
        saveOriginalWallpapers()
    }

    /// Saves the current wallpaper for each screen so it can be restored later
    private func saveOriginalWallpapers() {
        for screen in NSScreen.screens {
            if let url = NSWorkspace.shared.desktopImageURL(for: screen) {
                originalWallpaper[screen] = url
            }
        }
    }

    /// Updates the wallpaper with the given track's album art
    func updateWallpaper(for track: NowPlaying) async throws {
        guard let artwork = track.artworkImage else {
            throw WallpaperError.noArtwork
        }

        // Check cache first
        if let cachedURL = imageCache[track.cacheKey],
           fileManager.fileExists(atPath: cachedURL.path) {
            try await setWallpaper(url: cachedURL)
            return
        }

        // Get the main screen size
        guard let mainScreen = NSScreen.main else {
            throw WallpaperError.noScreen
        }

        let screenSize = mainScreen.frame.size

        // Generate the wallpaper image
        guard let wallpaperImage = imageProcessor.createWallpaperImage(from: artwork, for: screenSize) else {
            throw WallpaperError.imageGenerationFailed
        }

        // Save to file with unique name
        let filename = "\(track.cacheKey.hash).png"
        let fileURL = wallpaperDirectory.appendingPathComponent(filename)

        try imageProcessor.saveImage(wallpaperImage, to: fileURL)

        // Cache the URL
        imageCache[track.cacheKey] = fileURL

        // Set the wallpaper
        try await setWallpaper(url: fileURL)

        await MainActor.run {
            self.isActive = true
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

    enum WallpaperError: Error, LocalizedError {
        case noArtwork
        case noScreen
        case imageGenerationFailed
        case settingFailed(Error)

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
