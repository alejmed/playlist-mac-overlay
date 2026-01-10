# Media Detection Agent

This agent handles all Spotify and Apple Music detection logic for the PlaylistOverlay app.

## Responsibilities

- Implementing `SpotifyDetector.swift` for Spotify playback detection
- Implementing `AppleMusicDetector.swift` for Apple Music playback detection
- Implementing `MediaDetectionService.swift` as the coordinator
- Handling AppleScript execution for both players
- Managing DistributedNotificationCenter listeners for Spotify

## Key Technical Details

### Spotify Detection
- Listen to `DistributedNotificationCenter` for notification name: `com.spotify.client.PlaybackStateChanged`
- Notification userInfo contains: Artist, Name, Album, Player State, Duration, Track ID, Playback Position
- For artwork, extract track ID and fetch from Spotify's CDN or use AppleScript

### Apple Music Detection
- No notification API available - must poll via AppleScript
- Poll every 2-3 seconds when enabled
- AppleScript queries: player state, current track name, artist, album, artwork

### AppleScript Examples

**Spotify:**
```applescript
tell application "Spotify"
    set trackName to name of current track
    set trackArtist to artist of current track
    set trackAlbum to album of current track
    set artworkURL to artwork url of current track
    return {trackName, trackArtist, trackAlbum, artworkURL}
end tell
```

**Apple Music:**
```applescript
tell application "Music"
    if player state is playing then
        set trackName to name of current track
        set trackArtist to artist of current track
        set trackAlbum to album of current track
        return {trackName, trackArtist, trackAlbum}
    end if
end tell
```

## Files to Modify

- `PlaylistOverlay/Services/MediaDetection/SpotifyDetector.swift`
- `PlaylistOverlay/Services/MediaDetection/AppleMusicDetector.swift`
- `PlaylistOverlay/Services/MediaDetection/MediaDetectionService.swift`
- `PlaylistOverlay/Utilities/AppleScriptRunner.swift`

## Testing

- Test with Spotify app running and playing music
- Test with Apple Music app running and playing music
- Test switching between apps
- Test pause/play state changes
- Test song transitions
