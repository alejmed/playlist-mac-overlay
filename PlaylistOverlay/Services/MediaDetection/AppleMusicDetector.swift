import AppKit
import Combine
import Foundation

/// Detects currently playing music from Apple Music
final class AppleMusicDetector: ObservableObject {

    @Published private(set) var nowPlaying: NowPlaying?
    @Published private(set) var isRunning = false

    private var pollingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    /// Polling interval in seconds
    var pollingInterval: TimeInterval = 2.0

    init() {
        setupAppStateListeners()
        checkIfMusicRunning()
    }

    deinit {
        stopPolling()
    }

    /// Sets up listeners for Music app launch/quit
    private func setupAppStateListeners() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .sink { [weak self] notification in
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                   app.bundleIdentifier == PlayerSource.appleMusic.bundleIdentifier {
                    self?.isRunning = true
                    self?.startPolling()
                }
            }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .sink { [weak self] notification in
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                   app.bundleIdentifier == PlayerSource.appleMusic.bundleIdentifier {
                    self?.isRunning = false
                    self?.stopPolling()
                    self?.nowPlaying = nil
                }
            }
            .store(in: &cancellables)
    }

    /// Checks if Music is currently running
    private func checkIfMusicRunning() {
        isRunning = AppleScriptRunner.isAppRunning(bundleId: PlayerSource.appleMusic.bundleIdentifier)
        if isRunning {
            startPolling()
        }
    }

    /// Starts polling for track changes
    func startPolling() {
        guard pollingTimer == nil else { return }

        // Immediately poll once
        Task { await refresh() }

        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    /// Stops polling
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    /// Refreshes the current track information
    func refresh() async {
        guard isRunning else { return }

        let script = """
        tell application "Music"
            if player state is playing then
                try
                    set trackName to name of current track
                    set trackArtist to artist of current track
                    set trackAlbum to album of current track
                    set trackID to database ID of current track as string
                    return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & trackID
                on error
                    return "|||||||"
                end try
            else
                return "|||||||"
            end if
        end tell
        """

        do {
            let result = try await AppleScriptRunner.execute(script)
            let parts = result.components(separatedBy: "|||")

            guard parts.count >= 4 else {
                await MainActor.run {
                    self.nowPlaying = nil
                }
                return
            }

            let title = parts[0]
            let artist = parts[1]
            let album = parts[2]
            let trackId = parts[3]

            let isPlaying = !title.isEmpty

            if isPlaying {
                let artworkImage = await fetchArtwork()

                // Only update if track changed
                let shouldUpdate = nowPlaying?.trackId != trackId || nowPlaying?.title != title

                if shouldUpdate {
                    await MainActor.run {
                        self.nowPlaying = NowPlaying(
                            title: title,
                            artist: artist,
                            album: album,
                            artworkURL: nil,
                            artworkImage: artworkImage,
                            source: .appleMusic,
                            isPlaying: true,
                            trackId: trackId
                        )
                    }
                }
            } else {
                await MainActor.run {
                    if self.nowPlaying?.isPlaying == true {
                        self.nowPlaying = self.nowPlaying.map { current in
                            NowPlaying(
                                title: current.title,
                                artist: current.artist,
                                album: current.album,
                                artworkURL: current.artworkURL,
                                artworkImage: current.artworkImage,
                                source: .appleMusic,
                                isPlaying: false,
                                trackId: current.trackId
                            )
                        }
                    }
                }
            }
        } catch {
            print("Failed to refresh Apple Music: \(error)")
        }
    }

    /// Fetches the current track's artwork using AppleScript
    private func fetchArtwork() async -> NSImage? {
        let script = """
        tell application "Music"
            try
                if player state is playing then
                    set artworkData to raw data of artwork 1 of current track
                    return artworkData
                end if
            on error
                return ""
            end try
        end tell
        """

        // AppleScript artwork retrieval is complex, use alternative approach
        // Try to get artwork via data
        let dataScript = """
        tell application "Music"
            try
                set artworkCount to count of artworks of current track
                if artworkCount > 0 then
                    set artData to data of artwork 1 of current track
                    return artData
                end if
            end try
        end tell
        """

        // For now, return nil and let the UI show a placeholder
        // Full artwork extraction requires writing to temp file via AppleScript
        return await extractArtworkViaFile()
    }

    /// Extracts artwork by saving to a temporary file
    private func extractArtworkViaFile() async -> NSImage? {
        let tempPath = NSTemporaryDirectory() + "apple_music_artwork.png"

        let script = """
        tell application "Music"
            try
                if player state is playing then
                    set artworkData to data of artwork 1 of current track
                    set artworkFormat to format of artwork 1 of current track

                    set filePath to POSIX file "\(tempPath)"
                    set fileRef to open for access filePath with write permission
                    set eof fileRef to 0
                    write artworkData to fileRef
                    close access fileRef

                    return "success"
                end if
            on error errMsg
                try
                    close access filePath
                end try
                return "error: " & errMsg
            end try
        end tell
        """

        do {
            let result = try await AppleScriptRunner.execute(script)
            if result == "success" {
                return NSImage(contentsOfFile: tempPath)
            }
        } catch {
            print("Failed to extract Apple Music artwork: \(error)")
        }

        return nil
    }
}
