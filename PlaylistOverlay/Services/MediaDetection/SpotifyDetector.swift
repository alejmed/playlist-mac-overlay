import AppKit
import Combine
import Foundation

/// Detects currently playing music from Spotify using distributed notifications.
///
/// This class monitors Spotify's playback state by listening to the
/// `com.spotify.client.PlaybackStateChanged` distributed notification that
/// Spotify broadcasts whenever the playback state changes (play, pause, skip, etc.).
///
/// The detector also tracks whether Spotify is running and fetches album artwork
/// using AppleScript when track information is received.
///
/// ## Usage
/// ```swift
/// let detector = SpotifyDetector()
/// detector.$nowPlaying.sink { track in
///     print("Now playing: \(track?.title ?? "Nothing")")
/// }
/// ```
final class SpotifyDetector: ObservableObject {

    // MARK: - Published Properties

    /// The currently playing track information, or `nil` if nothing is playing
    @Published private(set) var nowPlaying: NowPlaying?

    /// Whether Spotify is currently running on the system
    @Published private(set) var isRunning = false

    // MARK: - Private Properties

    /// Set of Combine cancellables for notification subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initializes the Spotify detector and sets up notification listeners
    init() {
        setupNotificationListener()
        checkIfSpotifyRunning()

        // Refresh on startup to catch already-playing tracks
        if isRunning {
            Task {
                await refresh()
            }
        }
    }

    // MARK: - Private Methods

    /// Sets up distributed notification listeners for Spotify playback changes.
    ///
    /// Listens for three types of notifications:
    /// 1. **Playback state changes** - When Spotify plays, pauses, or skips tracks
    /// 2. **App launch** - When Spotify is opened
    /// 3. **App termination** - When Spotify is quit
    ///
    /// All notification handlers run on the main thread to ensure thread-safe
    /// updates to published properties.
    private func setupNotificationListener() {
        DistributedNotificationCenter.default()
            .publisher(for: Notification.Name("com.spotify.client.PlaybackStateChanged"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handlePlaybackStateChanged(notification)
            }
            .store(in: &cancellables)

        // Also listen for app launch/quit
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .sink { [weak self] notification in
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                   app.bundleIdentifier == PlayerSource.spotify.bundleIdentifier {
                    self?.isRunning = true
                }
            }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .sink { [weak self] notification in
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                   app.bundleIdentifier == PlayerSource.spotify.bundleIdentifier {
                    self?.isRunning = false
                    self?.nowPlaying = nil
                }
            }
            .store(in: &cancellables)
    }

    /// Checks if Spotify is currently running on the system.
    ///
    /// Uses AppleScript to query if the Spotify app is running.
    /// Updates the `isRunning` property based on the result.
    private func checkIfSpotifyRunning() {
        isRunning = AppleScriptRunner.isAppRunning(bundleId: PlayerSource.spotify.bundleIdentifier)
    }

    /// Handles Spotify playback state change notifications.
    ///
    /// Parses the notification's `userInfo` dictionary to extract:
    /// - Player state (Playing/Paused/Stopped)
    /// - Track metadata (title, artist, album, track ID)
    ///
    /// When a track is playing, asynchronously fetches the artwork via AppleScript
    /// and updates the `nowPlaying` property.
    ///
    /// - Parameter notification: The distributed notification from Spotify
    private func handlePlaybackStateChanged(_ notification: Notification) {
        print("🎧 [SpotifyDetector] Received notification!")
        guard let userInfo = notification.userInfo else {
            print("⚠️ [SpotifyDetector] No userInfo in notification")
            return
        }

        let playerState = userInfo["Player State"] as? String ?? ""
        let isPlaying = playerState == "Playing"
        print("   - Player State: \(playerState)")
        print("   - Is Playing: \(isPlaying)")

        guard isPlaying else {
            print("⏸️ [SpotifyDetector] Not playing, updating state")
            nowPlaying = nowPlaying.map { current in
                NowPlaying(
                    title: current.title,
                    artist: current.artist,
                    album: current.album,
                    artworkURL: current.artworkURL,
                    artworkImage: current.artworkImage,
                    source: .spotify,
                    isPlaying: false,
                    trackId: current.trackId
                )
            }
            return
        }

        let title = userInfo["Name"] as? String ?? ""
        let artist = userInfo["Artist"] as? String ?? ""
        let album = userInfo["Album"] as? String ?? ""
        let trackId = userInfo["Track ID"] as? String

        print("🎵 [SpotifyDetector] Track info:")
        print("   - Title: \(title)")
        print("   - Artist: \(artist)")
        print("   - Album: \(album)")

        // Fetch artwork asynchronously
        Task { @MainActor in
            print("🖼️ [SpotifyDetector] Fetching artwork...")
            let (artworkURL, artworkImage) = await fetchArtwork()
            print("   - Artwork URL: \(artworkURL?.absoluteString ?? "nil")")
            print("   - Artwork Image: \(artworkImage != nil ? "✅ Loaded" : "❌ Failed")")

            self.nowPlaying = NowPlaying(
                title: title,
                artist: artist,
                album: album,
                artworkURL: artworkURL,
                artworkImage: artworkImage,
                source: .spotify,
                isPlaying: true,
                trackId: trackId
            )
        }
    }

    /// Fetches the current track's artwork using AppleScript and downloads the image.
    ///
    /// Spotify provides artwork URLs via the `artwork url of current track` AppleScript
    /// property. This method:
    /// 1. Queries Spotify for the artwork URL
    /// 2. Downloads the image data from that URL
    /// 3. Converts it to an `NSImage`
    ///
    /// - Returns: A tuple containing the artwork URL and the downloaded image,
    ///            or `(nil, nil)` if fetching fails
    private func fetchArtwork() async -> (URL?, NSImage?) {
        let script = """
        tell application "Spotify"
            if player state is playing then
                return artwork url of current track
            end if
        end tell
        """

        do {
            let urlString = try await AppleScriptRunner.execute(script)
            guard let url = URL(string: urlString) else {
                return (nil, nil)
            }

            // Download the image
            let (data, _) = try await URLSession.shared.data(from: url)
            let image = NSImage(data: data)

            return (url, image)
        } catch {
            print("Failed to fetch Spotify artwork: \(error)")
            return (nil, nil)
        }
    }

    // MARK: - Public Methods

    /// Manually refreshes the current track information from Spotify.
    ///
    /// This method polls Spotify via AppleScript to get the current track's
    /// metadata. It's useful for:
    /// - Initial app launch to get current state
    /// - Recovering from errors
    /// - Manual refresh requests
    ///
    /// The method returns immediately if Spotify is not running.
    ///
    /// - Note: Normally, track updates are handled automatically via notifications,
    ///         so this method is only needed in specific scenarios.
    func refresh() async {
        guard isRunning else { return }

        let script = """
        tell application "Spotify"
            if player state is playing then
                set trackName to name of current track
                set trackArtist to artist of current track
                set trackAlbum to album of current track
                set trackID to id of current track
                return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & trackID
            else
                return "|||||||"
            end if
        end tell
        """

        do {
            let result = try await AppleScriptRunner.execute(script)
            let parts = result.components(separatedBy: "|||")

            guard parts.count >= 4 else { return }

            let title = parts[0]
            let artist = parts[1]
            let album = parts[2]
            let trackId = parts[3]

            let isPlaying = !title.isEmpty

            if isPlaying {
                let (artworkURL, artworkImage) = await fetchArtwork()

                await MainActor.run {
                    self.nowPlaying = NowPlaying(
                        title: title,
                        artist: artist,
                        album: album,
                        artworkURL: artworkURL,
                        artworkImage: artworkImage,
                        source: .spotify,
                        isPlaying: true,
                        trackId: trackId
                    )
                }
            } else {
                await MainActor.run {
                    self.nowPlaying = nil
                }
            }
        } catch {
            print("Failed to refresh Spotify: \(error)")
        }
    }
}
