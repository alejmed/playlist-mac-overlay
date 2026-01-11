import Combine
import Foundation

/// Coordinates media detection from multiple sources
final class MediaDetectionService: ObservableObject {

    @Published private(set) var currentlyPlaying: NowPlaying?
    @Published var spotifyEnabled = true
    @Published var appleMusicEnabled = true

    let spotifyDetector = SpotifyDetector()
    let appleMusicDetector = AppleMusicDetector()

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()

        // Refresh all detectors on startup to catch already-playing tracks
        Task {
            await refreshAll()
        }
    }

    /// Sets up Combine bindings to merge detection sources
    private func setupBindings() {
        // Combine both sources, prioritizing whichever is actively playing
        Publishers.CombineLatest4(
            spotifyDetector.$nowPlaying,
            appleMusicDetector.$nowPlaying,
            $spotifyEnabled,
            $appleMusicEnabled
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .map { [weak self] spotify, appleMusic, spotifyEnabled, appleMusicEnabled in
            self?.determineCurrentTrack(
                spotify: spotifyEnabled ? spotify : nil,
                appleMusic: appleMusicEnabled ? appleMusic : nil
            )
        }
        .assign(to: &$currentlyPlaying)
    }

    /// Determines which track should be displayed based on playback state
    private func determineCurrentTrack(spotify: NowPlaying?, appleMusic: NowPlaying?) -> NowPlaying? {
        // Priority: actively playing track wins
        if let spotify = spotify, spotify.isPlaying {
            return spotify
        }

        if let appleMusic = appleMusic, appleMusic.isPlaying {
            return appleMusic
        }

        // If neither is playing, show the most recent paused track
        if let spotify = spotify, spotify.hasTrackInfo {
            return spotify
        }

        if let appleMusic = appleMusic, appleMusic.hasTrackInfo {
            return appleMusic
        }

        return nil
    }

    /// Manually refreshes all enabled sources
    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            if spotifyEnabled {
                group.addTask {
                    await self.spotifyDetector.refresh()
                }
            }

            if appleMusicEnabled {
                group.addTask {
                    await self.appleMusicDetector.refresh()
                }
            }
        }
    }

    /// Checks if any supported player is running
    var isAnyPlayerRunning: Bool {
        spotifyDetector.isRunning || appleMusicDetector.isRunning
    }

    /// Checks if any music is currently playing
    var isPlaying: Bool {
        currentlyPlaying?.isPlaying ?? false
    }
}
