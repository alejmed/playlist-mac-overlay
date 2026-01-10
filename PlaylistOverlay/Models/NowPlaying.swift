import AppKit
import Foundation

/// Represents the currently playing track information
struct NowPlaying: Equatable {
    let title: String
    let artist: String
    let album: String
    let artworkURL: URL?
    let artworkImage: NSImage?
    let source: PlayerSource
    let isPlaying: Bool
    let trackId: String?

    /// Unique identifier for caching purposes
    var cacheKey: String {
        "\(source.rawValue)-\(artist)-\(album)-\(title)"
    }

    /// Creates a NowPlaying instance with minimal information
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

    /// Check if this represents actual track data
    var hasTrackInfo: Bool {
        !title.isEmpty && !artist.isEmpty
    }

    // MARK: - Equatable

    static func == (lhs: NowPlaying, rhs: NowPlaying) -> Bool {
        lhs.title == rhs.title &&
        lhs.artist == rhs.artist &&
        lhs.album == rhs.album &&
        lhs.source == rhs.source &&
        lhs.isPlaying == rhs.isPlaying &&
        lhs.trackId == rhs.trackId
    }
}
