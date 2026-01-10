import SwiftUI

/// Displays album art with a blurred background
struct AlbumArtView: View {
    let nowPlaying: NowPlaying
    var showTrackInfo: Bool = true
    var blurRadius: CGFloat = 50

    @State private var imageLoaded = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Blurred background
                if let artwork = nowPlaying.artworkImage {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .blur(radius: blurRadius)
                        .clipped()
                } else {
                    // Placeholder gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue, .cyan]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                // Dark overlay for better contrast
                Color.black.opacity(0.3)

                VStack(spacing: 20) {
                    // Centered album art
                    if let artwork = nowPlaying.artworkImage {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: min(geometry.size.width * 0.6, 400))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
                            .scaleEffect(imageLoaded ? 1.0 : 0.8)
                            .opacity(imageLoaded ? 1.0 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: imageLoaded)
                            .onAppear {
                                imageLoaded = true
                            }
                    } else {
                        // Placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 200)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }

                    // Track info
                    if showTrackInfo {
                        VStack(spacing: 8) {
                            Text(nowPlaying.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(nowPlaying.artist)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)

                            if !nowPlaying.album.isEmpty {
                                Text(nowPlaying.album)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                                    .lineLimit(1)
                            }
                        }
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: nowPlaying.cacheKey) { _, _ in
            imageLoaded = false
            withAnimation {
                imageLoaded = true
            }
        }
    }
}

/// Compact album art view for menu bar popover
struct CompactAlbumArtView: View {
    let nowPlaying: NowPlaying

    var body: some View {
        HStack(spacing: 12) {
            // Album art thumbnail
            if let artwork = nowPlaying.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(nowPlaying.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(nowPlaying.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: nowPlaying.source.iconName)
                        .font(.caption2)

                    Text(nowPlaying.source.rawValue)
                        .font(.caption2)

                    if nowPlaying.isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(8)
    }
}

#Preview {
    AlbumArtView(
        nowPlaying: NowPlaying(
            title: "Blinding Lights",
            artist: "The Weeknd",
            album: "After Hours",
            artworkURL: nil,
            artworkImage: nil,
            source: .spotify,
            isPlaying: true,
            trackId: "123"
        )
    )
    .frame(width: 800, height: 600)
}
