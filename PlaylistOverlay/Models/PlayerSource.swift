import Foundation

/// Represents the supported music player applications.
///
/// This enum defines the music players that the app can monitor for
/// currently playing track information. Each case provides metadata
/// about the player including bundle identifiers, notification names,
/// and display information.
///
/// The app uses different detection mechanisms for each player:
/// - **Spotify**: Real-time detection via `DistributedNotificationCenter`
/// - **Apple Music**: Polling via AppleScript (no notification API available)
enum PlayerSource: String, Codable, CaseIterable {

    /// Spotify music player
    case spotify = "Spotify"

    /// Apple Music (formerly iTunes)
    case appleMusic = "Apple Music"

    // MARK: - Computed Properties

    /// The macOS bundle identifier for the player application.
    ///
    /// Used to check if the application is running via `NSRunningApplication`.
    var bundleIdentifier: String {
        switch self {
        case .spotify:
            return "com.spotify.client"
        case .appleMusic:
            return "com.apple.Music"
        }
    }

    /// The distributed notification name for playback state changes.
    ///
    /// Spotify broadcasts a distributed notification whenever playback state changes
    /// (play, pause, skip, etc.). Apple Music does not provide a notification API,
    /// so this returns `nil` for that case.
    ///
    /// - Returns: The notification name for Spotify, or `nil` for Apple Music
    var notificationName: Notification.Name? {
        switch self {
        case .spotify:
            return Notification.Name("com.spotify.client.PlaybackStateChanged")
        case .appleMusic:
            return nil // Apple Music doesn't broadcast notifications
        }
    }

    /// The SF Symbol icon name for displaying this player in the UI.
    ///
    /// Used in menu bar icons, settings, and other UI elements to visually
    /// represent the music player.
    var iconName: String {
        switch self {
        case .spotify:
            return "music.note"
        case .appleMusic:
            return "music.quarternote.3"
        }
    }
}
