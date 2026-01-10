import AppKit
import Foundation

/// Executes AppleScript commands and returns results.
///
/// This utility provides async/await wrappers around `NSAppleScript` for executing
/// AppleScript code and checking if applications are running.
///
/// All AppleScript execution happens on a background queue to avoid blocking the main thread.
final class AppleScriptRunner {

    enum AppleScriptError: Error, LocalizedError {
        case scriptCreationFailed
        case executionFailed(String)
        case noResult

        var errorDescription: String? {
            switch self {
            case .scriptCreationFailed:
                return "Failed to create AppleScript"
            case .executionFailed(let message):
                return "AppleScript execution failed: \(message)"
            case .noResult:
                return "AppleScript returned no result"
            }
        }
    }

    /// Executes an AppleScript and returns the result as a string
    static func execute(_ script: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                guard let appleScript = NSAppleScript(source: script) else {
                    continuation.resume(throwing: AppleScriptError.scriptCreationFailed)
                    return
                }

                let result = appleScript.executeAndReturnError(&error)

                if let error = error {
                    let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    continuation.resume(throwing: AppleScriptError.executionFailed(message))
                    return
                }

                guard let stringValue = result.stringValue else {
                    continuation.resume(throwing: AppleScriptError.noResult)
                    return
                }

                continuation.resume(returning: stringValue)
            }
        }
    }

    /// Executes an AppleScript and returns the result as a list of strings
    static func executeList(_ script: String) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                guard let appleScript = NSAppleScript(source: script) else {
                    continuation.resume(throwing: AppleScriptError.scriptCreationFailed)
                    return
                }

                let result = appleScript.executeAndReturnError(&error)

                if let error = error {
                    let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    continuation.resume(throwing: AppleScriptError.executionFailed(message))
                    return
                }

                var strings: [String] = []
                let count = result.numberOfItems

                for i in 1...count {
                    if let item = result.atIndex(i)?.stringValue {
                        strings.append(item)
                    }
                }

                continuation.resume(returning: strings)
            }
        }
    }

    /// Checks if an application is running
    static func isAppRunning(bundleId: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == bundleId
        }
    }
}
