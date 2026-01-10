import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// Processes images to create blurred wallpaper backgrounds
final class ImageProcessor {

    private let context = CIContext()

    /// Default blur radius for background
    var blurRadius: CGFloat = 60

    /// Size ratio of centered album art relative to screen height
    var albumArtSizeRatio: CGFloat = 0.3

    /// Whether to show text overlay with song and artist info
    var showTextOverlay: Bool = true

    /// Creates a wallpaper image with blurred background and centered album art
    /// - Parameters:
    ///   - artwork: The album artwork image
    ///   - screenSize: The target screen size
    ///   - title: The song title for text overlay
    ///   - artist: The artist name for text overlay
    /// - Returns: The generated wallpaper image
    func createWallpaperImage(from artwork: NSImage, for screenSize: CGSize, title: String, artist: String) -> NSImage? {
        guard let cgImage = artwork.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)

        // Create blurred background
        guard let blurredBackground = createBlurredBackground(from: ciImage, targetSize: screenSize) else {
            return nil
        }

        // Create centered album art
        let albumArtSize = min(screenSize.width, screenSize.height) * albumArtSizeRatio
        guard let centeredArt = createCenteredAlbumArt(from: ciImage, artSize: albumArtSize, canvasSize: screenSize) else {
            return nil
        }

        // Composite over a solid black base to avoid any transparent edges
        let blackBase = CIImage(color: .black).cropped(to: CGRect(origin: .zero, size: screenSize))
        let backgroundOverBlack = blurredBackground.composited(over: blackBase)
        let composited = centeredArt.composited(over: backgroundOverBlack)

        // Render to NSImage
        guard let outputCGImage = context.createCGImage(composited, from: CGRect(origin: .zero, size: screenSize)) else {
            return nil
        }

        var wallpaperImage = NSImage(cgImage: outputCGImage, size: screenSize)

        // Add text overlay if enabled
        if showTextOverlay {
            wallpaperImage = drawText(on: wallpaperImage, title: title, artist: artist, canvasSize: screenSize)
        }

        return wallpaperImage
    }

    /// Creates a blurred and scaled background image
    private func createBlurredBackground(from image: CIImage, targetSize: CGSize) -> CIImage? {
        // Scale to fill the target size
        let scaleX = targetSize.width / image.extent.width
        let scaleY = targetSize.height / image.extent.height
        let scale = max(scaleX, scaleY)

        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Center crop to target size
        let xOffset = (scaledImage.extent.width - targetSize.width) / 2
        let yOffset = (scaledImage.extent.height - targetSize.height) / 2
        let croppedImage = scaledImage.cropped(to: CGRect(
            x: xOffset,
            y: yOffset,
            width: targetSize.width,
            height: targetSize.height
        ))

        // Translate to origin
        let translatedImage = croppedImage.transformed(by: CGAffineTransform(translationX: -xOffset, y: -yOffset))

        // Apply blur
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = translatedImage
        blurFilter.radius = Float(blurRadius)

        guard let blurredImage = blurFilter.outputImage else {
            return nil
        }

        // Crop to remove blur edge artifacts
        return blurredImage.cropped(to: CGRect(origin: .zero, size: targetSize))
    }

    /// Creates a centered album art image on a transparent canvas
    private func createCenteredAlbumArt(from image: CIImage, artSize: CGFloat, canvasSize: CGSize) -> CIImage? {
        // Scale the album art
        let scale = artSize / max(image.extent.width, image.extent.height)
        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Calculate center position
        let xOffset = (canvasSize.width - scaledImage.extent.width) / 2
        let yOffset = (canvasSize.height - scaledImage.extent.height) / 2

        // Translate to center
        let centeredImage = scaledImage.transformed(by: CGAffineTransform(translationX: xOffset, y: yOffset))

        // Apply rounded corners
        let roundedImage = applyRoundedCorners(to: centeredImage, radius: artSize * 0.05)

        return roundedImage ?? centeredImage
    }

    /// Applies rounded corners to an image
    private func applyRoundedCorners(to image: CIImage, radius: CGFloat) -> CIImage? {
        let rect = image.extent
        let roundedRect = CIFilter.roundedRectangleGenerator()
        roundedRect.extent = rect
        roundedRect.radius = Float(radius)
        roundedRect.color = CIColor(red: 1, green: 1, blue: 1, alpha: 1)

        guard let mask = roundedRect.outputImage else { return nil }

        let masked = image.applyingFilter("CIBlendWithAlphaMask", parameters: [
            kCIInputMaskImageKey: mask
        ])

        return masked
    }

    /// Adds a shadow effect to the image
    private func addShadow(to image: CIImage) -> CIImage {
        // Create shadow
        let shadowFilter = CIFilter.gaussianBlur()
        shadowFilter.inputImage = image
        shadowFilter.radius = 20

        guard let shadow = shadowFilter.outputImage else {
            return image
        }

        // Offset and darken shadow
        let offsetShadow = shadow
            .transformed(by: CGAffineTransform(translationX: 0, y: -10))
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.5)
            ])

        let base = CIImage(color: .black).cropped(to: image.extent)
        return image.composited(over: offsetShadow.composited(over: base))
    }

    /// Saves an NSImage to a file URL
    func saveImage(_ image: NSImage, to url: URL, format: NSBitmapImageRep.FileType = .png) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: format, properties: [:]) else {
            throw ImageProcessorError.saveFailed
        }

        try data.write(to: url)
    }

    /// Draws text overlay on the wallpaper image
    private func drawText(on image: NSImage, title: String, artist: String, canvasSize: CGSize) -> NSImage {
        let newImage = NSImage(size: canvasSize)
        newImage.lockFocus()

        // Draw the original image
        image.draw(in: NSRect(origin: .zero, size: canvasSize))

        // Calculate positions
        let albumArtSize = min(canvasSize.width, canvasSize.height) * albumArtSizeRatio
        let albumArtY = (canvasSize.height - albumArtSize) / 2
        let textY = albumArtY + albumArtSize + 40 // Below the album art

        // Title
        let titleFont = NSFont.systemFont(ofSize: 48, weight: .semibold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.white
        ]
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleSize = titleString.size()
        let titleX = (canvasSize.width - titleSize.width) / 2
        titleString.draw(at: NSPoint(x: titleX, y: textY))

        // Artist
        let artistFont = NSFont.systemFont(ofSize: 36, weight: .regular)
        let artistAttributes: [NSAttributedString.Key: Any] = [
            .font: artistFont,
            .foregroundColor: NSColor.white.withAlphaComponent(0.8)
        ]
        let artistString = NSAttributedString(string: artist, attributes: artistAttributes)
        let artistSize = artistString.size()
        let artistX = (canvasSize.width - artistSize.width) / 2
        let artistY = textY - 60 // Above title
        artistString.draw(at: NSPoint(x: artistX, y: artistY))

        newImage.unlockFocus()
        return newImage
    }

    enum ImageProcessorError: Error {
        case saveFailed
    }
}
