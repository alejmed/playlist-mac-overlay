import Foundation

/// Represents the source music player application
enum PlayerSource: String, Codable, CaseIterable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"

    /// The bundle identifier for the player application
    var bundleIdentifier: String {
        switch self {
        case .spotify:
            return "com.spotify.client"
        case .appleMusic:
            return "com.apple.Music"
        }
    }

    /// The notification name for playback state changes (Spotify only)
    var notificationName: Notification.Name? {
        switch self {
        case .spotify:
            return Notification.Name("com.spotify.client.PlaybackStateChanged")
        case .appleMusic:
            return nil // Apple Music doesn't broadcast notifications
        }
    }

    /// Display icon SF Symbol name
    var iconName: String {
        switch self {
        case .spotify:
            return "music.note"
        case .appleMusic:
            return "music.quarternote.3"
        }
    }
}
