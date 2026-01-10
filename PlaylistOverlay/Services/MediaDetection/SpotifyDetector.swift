import AppKit
import Combine
import Foundation

/// Detects currently playing music from Spotify
final class SpotifyDetector: ObservableObject {

    @Published private(set) var nowPlaying: NowPlaying?
    @Published private(set) var isRunning = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNotificationListener()
        checkIfSpotifyRunning()
    }

    /// Sets up the distributed notification listener for Spotify playback changes
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

    /// Checks if Spotify is currently running
    private func checkIfSpotifyRunning() {
        isRunning = AppleScriptRunner.isAppRunning(bundleId: PlayerSource.spotify.bundleIdentifier)
    }

    /// Handles Spotify playback state change notifications
    private func handlePlaybackStateChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        let playerState = userInfo["Player State"] as? String ?? ""
        let isPlaying = playerState == "Playing"

        guard isPlaying else {
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

        // Fetch artwork asynchronously
        Task { @MainActor in
            let (artworkURL, artworkImage) = await fetchArtwork()

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

    /// Fetches the current track's artwork using AppleScript
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

    /// Manually refreshes the current track information
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
