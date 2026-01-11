# Development Workflow Guide for Playlist Overlay

This guide documents the development workflow used for implementing features and fixing bugs in this project. Follow these patterns for consistent, high-quality contributions.

## Table of Contents

1. [Branch Strategy](#branch-strategy)
2. [Feature Development Workflow](#feature-development-workflow)
3. [Bug Fix Workflow](#bug-fix-workflow)
4. [Code Investigation Process](#code-investigation-process)
5. [Commit Message Standards](#commit-message-standards)
6. [Testing and Validation](#testing-and-validation)
7. [Project-Specific Notes](#project-specific-notes)

---

## Branch Strategy

### Branch Naming Convention

- **Features**: `refactor/descriptive-name` or `feature/descriptive-name`
  - Example: `refactor/desktop-overlay`
- **Bug Fixes**: `fix/descriptive-name`
  - Example: `fix/detect-playing-on-startup`

### Branch Lifecycle

1. **Create branch from master**
   ```bash
   git checkout -b fix/your-feature-name
   ```

2. **Work iteratively with commits**
   - Make small, focused commits
   - Push frequently to remote
   - Iterate on feedback

3. **Merge to master when ready**
   ```bash
   git checkout master
   git merge fix/your-feature-name
   git push origin master
   ```

---

## Feature Development Workflow

### Step 1: Understand the Request

- **Read the requirements carefully**
- Ask clarifying questions if needed
- Identify architectural implications

### Step 2: Create a Todo List

Use the TodoWrite tool to plan your work:

```
[
  {"content": "Research existing implementation", "activeForm": "Researching...", "status": "pending"},
  {"content": "Design new architecture", "activeForm": "Designing...", "status": "pending"},
  {"content": "Implement core functionality", "activeForm": "Implementing...", "status": "pending"},
  {"content": "Update UI components", "activeForm": "Updating UI...", "status": "pending"},
  {"content": "Test and validate", "activeForm": "Testing...", "status": "pending"}
]
```

**Important**: Update todo status as you progress:
- Set ONE task to `in_progress` before starting work
- Mark as `completed` IMMEDIATELY after finishing
- Always have exactly ONE task in_progress at a time

### Step 3: Investigate Existing Code

**Read files before modifying them**:

```bash
# Find relevant files
Glob: "**/*.swift"

# Search for patterns
Grep: pattern="WallpaperService" output_mode="files_with_matches"

# Read the actual implementation
Read: file_path="/path/to/file.swift"
```

**Understanding Architecture**:
- Identify services, controllers, and views
- Trace data flow through the app
- Note dependencies and relationships
- Look for existing patterns to follow

### Step 4: Implement Changes Incrementally

**Example from Desktop Overlay Refactor**:

1. **Create new components first**
   - Write new classes/files
   - Test compilation

2. **Update integration points**
   - Modify AppState to use new components
   - Update UI references

3. **Clean up old code** (if applicable)
   - Comment on what's deprecated
   - Don't break existing functionality

### Step 5: Commit with Detailed Messages

See [Commit Message Standards](#commit-message-standards) below.

### Step 6: Push and Make Visible

```bash
git push -u origin feature/your-branch-name
```

This creates the branch on GitHub and makes it visible.

---

## Bug Fix Workflow

### Step 1: Reproduce and Understand

**Ask questions to clarify the bug**:
- When does it occur?
- What's the expected behavior?
- What's the actual behavior?

### Step 2: Investigate Root Cause

**Use debugging strategies**:

1. **Read relevant code**:
   ```
   Read: "MediaDetectionService.swift"
   Read: "SpotifyDetector.swift"
   ```

2. **Trace execution flow**:
   - Follow initialization code
   - Check event handlers
   - Look for conditional logic

3. **Identify the gap**:
   - What's missing?
   - What's executing when it shouldn't?
   - What's NOT executing when it should?

**Example from Startup Detection Bug**:
```
Problem: Song not detected on app startup
Investigation: Read detector initialization code
Root Cause: Spotify only responds to notifications, no polling on startup
Solution: Add refresh() call in init() when app is already running
```

### Step 3: Create Todo List for Fix

```
[
  {"content": "Identify root cause", "activeForm": "Identifying root cause", "status": "completed"},
  {"content": "Implement fix in Service", "activeForm": "Implementing fix", "status": "in_progress"},
  {"content": "Test with both sources", "activeForm": "Testing fix", "status": "pending"},
  {"content": "Commit and push", "activeForm": "Committing and pushing", "status": "pending"}
]
```

### Step 4: Implement Minimal Fix

**Keep fixes focused and minimal**:
- Change only what's necessary
- Don't refactor while fixing bugs (unless absolutely required)
- Add comments explaining the fix

**Example**:
```swift
init() {
    setupBindings()

    // Refresh all detectors on startup to catch already-playing tracks
    Task {
        await refreshAll()
    }
}
```

### Step 5: Test Iteratively

- After each commit, ask user to test
- Be prepared to iterate on the fix
- Each iteration = new commit on same branch

### Step 6: Accumulate Fixes on Same Branch

**Pattern from this session**:
```
fix/detect-playing-on-startup:
  ├── e1c14a9 - Fix: Detect already-playing tracks on app startup
  ├── 413721b - Fix: Show desktop overlay on startup when enabled
  ├── 39c6026 - Fix: Desktop overlay now covers entire screen width
  └── ee94db7 - Fix: Remove clipping and scale background to cover full screen
```

All related fixes go on the same branch, then merge once when complete.

---

## Code Investigation Process

### Finding Files

**Use Glob for pattern matching**:
```
Glob: "**/*.swift"           # All Swift files
Glob: "**/Services/**/*.swift"  # Services only
Glob: "**/*Detector*.swift"     # Files with "Detector" in name
```

### Searching Code

**Use Grep for content search**:
```
Grep: pattern="WallpaperService" output_mode="files_with_matches"
Grep: pattern="init\(\)" output_mode="content" glob="**/*.swift"
```

### Reading Files

**Read strategically**:
- Read the full file first to understand context
- Use offset/limit only for very large files
- Read related files in parallel when possible

**Example**:
```
Read: "AppState.swift"
Read: "WallpaperService.swift"  # Read both in parallel
```

### Understanding SwiftUI Architecture

**Key patterns in this project**:

1. **AppState** - Central state manager
   - `@StateObject` in main app
   - Shared via `@EnvironmentObject`
   - Coordinates all services

2. **Services** - Business logic
   - `MediaDetectionService` - Coordinates detectors
   - `SpotifyDetector` / `AppleMusicDetector` - Source-specific
   - `DesktopOverlayController` - Manages overlay window

3. **Views** - UI components
   - SwiftUI views for UI
   - NSWindow subclasses for native windows
   - `NSHostingView` to bridge SwiftUI into AppKit

---

## Commit Message Standards

### Format

```
<Type>: <Short description>

## Problem (for fixes only)
Clear statement of what was broken

## Root Cause (for fixes only)
Technical explanation of why it was broken

## Solution / What Changed
Bulleted list of changes made

## Benefits / Result
What improved or what works now

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Types

- `Fix:` - Bug fixes
- `Refactor:` - Architecture changes
- `Feature:` - New functionality
- `Docs:` - Documentation only
- `Chore:` - Maintenance (dependencies, config)

### Example: Feature Commit

```
Refactor: Replace wallpaper modification with desktop overlay window

Major architectural change to improve user experience and system integration.

## What Changed

Instead of modifying the actual desktop wallpaper, the app now creates a
desktop-level overlay window that sits between the wallpaper and regular apps.

## Benefits

1. **No wallpaper pollution**: Doesn't create/leave PNG files in ~/Library
2. **Auto-cleanup**: Overlay disappears when app quits (no restoration needed)
3. **Cleaner architecture**: No need to save/restore original wallpapers
4. **Better UX**: Users can still see their original wallpaper when app is off

## Technical Details

### New: DesktopOverlayWindow
- NSWindow subclass positioned at desktop level (.desktopWindow + 1)
- Fullscreen, borderless, non-interactive (clicks pass through)
- Uses existing AlbumArtView for blurred album art rendering

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Example: Bug Fix Commit

```
Fix: Detect already-playing tracks on app startup

## Problem
When the app launched while Spotify or Apple Music was already playing a song,
the track wasn't detected until the user skipped to the next song.

## Root Cause
- **SpotifyDetector** only responds to distributed notifications
- When app starts, no notification is broadcast for already-playing tracks
- **AppleMusicDetector** was working because it immediately polls on startup

## Solution
1. Call refreshAll() in MediaDetectionService initialization
2. Add startup refresh in SpotifyDetector when Spotify is already running
3. Both detectors now poll current state immediately on app launch

## Result
App now detects and displays already-playing tracks on startup for both
Spotify and Apple Music.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

---

## Testing and Validation

### Manual Testing Checklist

After implementing changes, verify:

1. **Build succeeds**
   ```bash
   xcodegen generate  # Regenerate project if needed
   ./build.sh         # Build the app
   ```

2. **Core functionality works**
   - Test the happy path
   - Test edge cases
   - Test with both Spotify and Apple Music (if applicable)

3. **No regressions**
   - Existing features still work
   - UI still responsive
   - No crashes on startup/shutdown

### Iterative Testing

**Pattern used in this session**:
1. Push commit
2. User tests
3. User reports issue
4. Investigate and fix
5. Push another commit on same branch
6. Repeat until working

**Don't merge until user confirms all issues resolved**

---

## Project-Specific Notes

### Xcode Project Generation

This project uses **XcodeGen** to generate the Xcode project from `project.yml`.

**When adding new files**:
```bash
xcodegen generate
```

This regenerates `PlaylistOverlay.xcodeproj/project.pbxproj` to include new files.

**Always commit the updated project.pbxproj after adding files.**

### macOS Window Levels

When working with overlay windows, understand window levels:

```
.desktopWindow      = Wallpaper level (lowest)
.desktopWindow + 1  = Desktop overlay (our custom level)
.normal            = Regular app windows
.floating          = Floating panels (like our overlay widget)
```

### SwiftUI + AppKit Integration

**NSHostingView Pattern**:
```swift
let contentView = NSHostingView(rootView: SomeSwiftUIView())
window.contentView = contentView
```

**Full-screen windows**:
```swift
// Get screen frame
let screenFrame = NSScreen.main?.frame ?? .zero

// Create borderless window
super.init(contentRect: screenFrame, styleMask: [.borderless], ...)

// Make non-interactive
window.ignoresMouseEvents = true
```

### AppleScript Integration

Both Spotify and Apple Music use AppleScript for querying:

- **Spotify**: Broadcasts notifications + AppleScript for artwork
- **Apple Music**: AppleScript polling only (no notifications)

**Pattern for polling on startup**:
```swift
init() {
    setupListeners()
    checkIfAppRunning()

    // Critical: Poll on startup to detect already-playing tracks
    if isRunning {
        Task { await refresh() }
    }
}
```

### Safe Area and Edge-to-Edge Rendering

**For desktop overlays that must fill the screen**:

```swift
// Window setup
window.setFrame(screenFrame, display: true, animate: false)

// SwiftUI view
.frame(maxWidth: .infinity, maxHeight: .infinity)
.ignoresSafeArea(.all)

// For blurred backgrounds with square images on wide screens
.scaleEffect(1.1) // Ensures coverage even after blur
```

---

## Quick Reference Checklist

### Starting New Feature
- [ ] Create branch: `git checkout -b feature/name`
- [ ] Create todo list with TodoWrite
- [ ] Read relevant existing code
- [ ] Implement incrementally
- [ ] Commit with detailed messages
- [ ] Push: `git push -u origin feature/name`

### Fixing Bug
- [ ] Create branch: `git checkout -b fix/name`
- [ ] Reproduce the issue
- [ ] Investigate root cause
- [ ] Create todo list
- [ ] Implement minimal fix
- [ ] Commit with Problem/Root Cause/Solution
- [ ] Push and iterate until confirmed working

### Before Merging
- [ ] All todos marked completed
- [ ] User has tested and approved
- [ ] Commit messages are descriptive
- [ ] No debug code left in
- [ ] Checkout master: `git checkout master`
- [ ] Merge: `git merge feature/name`
- [ ] Push: `git push origin master`

---

## Tips for AI Agents

1. **Always read before writing** - Never modify code you haven't read
2. **Use todos religiously** - Track every multi-step task
3. **Commit often** - Small, focused commits are better
4. **Detailed commit messages** - Future you will thank you
5. **Test iteratively** - Don't assume your first attempt is perfect
6. **Ask clarifying questions** - Don't guess requirements
7. **Follow existing patterns** - Don't reinvent the wheel
8. **One task at a time** - Focus on completing each todo fully
9. **Update todos immediately** - Mark completed as soon as done
10. **Communicate clearly** - Explain what you're doing and why

---

## Common Pitfalls to Avoid

❌ **Don't**: Modify code without reading it first
✅ **Do**: Read the file, understand the context, then modify

❌ **Don't**: Make large, sweeping changes in one commit
✅ **Do**: Make incremental commits that can be reviewed

❌ **Don't**: Write vague commit messages like "fix bug"
✅ **Do**: Explain the problem, root cause, and solution

❌ **Don't**: Assume your fix works without testing
✅ **Do**: Push and get user feedback iteratively

❌ **Don't**: Create new branch for every small fix
✅ **Do**: Accumulate related fixes on one branch

❌ **Don't**: Merge before user confirms it works
✅ **Do**: Iterate on the branch until approved

❌ **Don't**: Forget to regenerate Xcode project after adding files
✅ **Do**: Run `xcodegen generate` and commit the project file

---

## Summary

The key to successful development on this project:

1. **Plan** with todos
2. **Investigate** by reading code
3. **Implement** incrementally
4. **Commit** descriptively
5. **Test** iteratively
6. **Merge** when approved

Follow these patterns and you'll contribute high-quality, maintainable code to the project.

---

## Learnings

- If a UI element is already absent, avoid changing unrelated settings; document that no code change was required for that portion.
- Keep menu bar changes isolated to `MenuBarView.swift` unless the request explicitly targets Settings.
- Always switch back to the feature branch before committing when a merge attempt surfaces unstaged changes on `master`.
- Build output may include system tool warnings (e.g., `actool`, `appintentsmetadataprocessor`) even when the build succeeds.
