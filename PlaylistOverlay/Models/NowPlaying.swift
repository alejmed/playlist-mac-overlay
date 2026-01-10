import AppKit
import Foundation

/// Represents the currently playing track information from a supported media player.
///
/// This struct encapsulates all relevant metadata about a currently playing song,
/// including track information, artwork, playback state, and the source player.
/// It conforms to `Equatable` to enable comparison between track states,
/// which is useful for detecting song changes and avoiding redundant wallpaper updates.
struct NowPlaying: Equatable {

    // MARK: - Properties

    /// The title/name of the currently playing track
    let title: String

    /// The artist name of the currently playing track
    let artist: String

    /// The album name of the currently playing track
    let album: String

    /// Optional URL to fetch the album artwork (used for remote fetching)
    let artworkURL: URL?

    /// The album artwork image, if already fetched and available
    let artworkImage: NSImage?

    /// The source media player (Spotify or Apple Music)
    let source: PlayerSource

    /// Whether the track is currently playing (true) or paused (false)
    let isPlaying: Bool

    /// Optional unique identifier for the track (Spotify URI or Apple Music persistent ID)
    let trackId: String?

    // MARK: - Computed Properties

    /// Unique identifier for caching purposes based on source, artist, album, and title.
    ///
    /// This key is used to avoid regenerating wallpaper images when the same track
    /// is detected multiple times (e.g., when paused and resumed).
    var cacheKey: String {
        "\(source.rawValue)-\(artist)-\(album)-\(title)"
    }

    /// Check if this instance represents actual track data (non-empty title and artist).
    ///
    /// - Returns: `true` if both title and artist are non-empty, `false` otherwise
    var hasTrackInfo: Bool {
        !title.isEmpty && !artist.isEmpty
    }

    // MARK: - Factory Methods

    /// Creates an empty NowPlaying instance with default values for a given source.
    ///
    /// Useful for representing a "no track playing" state while maintaining
    /// the source player information.
    ///
    /// - Parameter source: The media player source
    /// - Returns: A NowPlaying instance with empty track information
    static func empty(source: PlayerSource) -> NowPlaying {
        NowPlaying(
            title: "",
            artist: "",
            album: "",
            artworkURL: nil,
            artworkImage: nil,
            source: source,
            isPlaying: false,
            trackId: nil
        )
    }

    // MARK: - Equatable

    /// Compares two NowPlaying instances for equality based on track metadata.
    ///
    /// Two tracks are considered equal if they have the same title, artist, album,
    /// source, playing state, and track ID. Artwork is intentionally excluded from
    /// comparison to avoid unnecessary updates when only the image data changes.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side NowPlaying instance
    ///   - rhs: The right-hand side NowPlaying instance
    /// - Returns: `true` if both instances represent the same track state
    static func == (lhs: NowPlaying, rhs: NowPlaying) -> Bool {
        lhs.title == rhs.title &&
        lhs.artist == rhs.artist &&
        lhs.album == rhs.album &&
        lhs.source == rhs.source &&
        lhs.isPlaying == rhs.isPlaying &&
        lhs.trackId == rhs.trackId
    }
}
