# Wallpaper Engine Agent

This agent handles image generation and wallpaper management for the PlaylistOverlay app.

## Responsibilities

- Implementing `ImageProcessor.swift` for creating blurred album art images
- Implementing `WallpaperService.swift` for setting macOS wallpapers
- Implementing `TransitionService.swift` for smooth transitions
- Managing temporary wallpaper files
- Supporting multiple displays

## Key Technical Details

### Image Processing
- Use Core Image `CIGaussianBlur` filter for blur effect
- Composite workflow:
  1. Load album artwork as CIImage
  2. Scale artwork to fill screen dimensions
  3. Apply heavy blur (radius ~50-80) for background
  4. Overlay sharp, centered album art (scaled to ~40% of screen height)
  5. Export as PNG/JPEG

### Wallpaper Setting
- Use `NSWorkspace.shared.setDesktopImageURL(_:for:options:)`
- Must use unique file paths (macOS caches by URL)
- Support all screens via `NSScreen.screens`

### Code Patterns

**Setting Wallpaper:**
```swift
let workspace = NSWorkspace.shared
for screen in NSScreen.screens {
    try workspace.setDesktopImageURL(imageURL, for: screen, options: [:])
}
```

**Core Image Blur:**
```swift
let blurFilter = CIFilter(name: "CIGaussianBlur")
blurFilter?.setValue(inputImage, forKey: kCIInputImageKey)
blurFilter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
let blurredImage = blurFilter?.outputImage
```

## Files to Modify

- `PlaylistOverlay/Services/WallpaperService.swift`
- `PlaylistOverlay/Services/ImageGeneratorService.swift`
- `PlaylistOverlay/Services/TransitionService.swift`
- `PlaylistOverlay/Utilities/ImageProcessor.swift`

## Performance Considerations

- Cache generated images by track ID
- Process images on background thread
- Clean up old temp files periodically
- Target image generation under 500ms

## Testing

- Test wallpaper setting on single display
- Test wallpaper setting on multiple displays
- Test image generation quality
- Test blur radius settings
- Test transition smoothness
