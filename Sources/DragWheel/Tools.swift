import Foundation

/// Optional helper tools (installed via Homebrew) that unlock some conversions.
enum Tool: String, CaseIterable {
    case ffmpeg, pandoc, soffice, magick, unar

    var displayName: String {
        switch self {
        case .ffmpeg: return "FFmpeg"
        case .pandoc: return "Pandoc"
        case .soffice: return "LibreOffice"
        case .magick: return "ImageMagick"
        case .unar: return "unar"
        }
    }

    var usedFor: String {
        switch self {
        case .ffmpeg: return "audio, video"
        case .pandoc: return "epub, markdown"
        case .soffice: return "presentations, spreadsheets"
        case .magick: return "webp/avif output (if macOS can't)"
        case .unar: return "rar fallback"
        }
    }

    var brewInstall: String {
        switch self {
        case .soffice: return "brew install --cask libreoffice"
        case .magick: return "brew install imagemagick"
        default: return "brew install \(rawValue)"
        }
    }

    var path: String? { ToolLocator.find(self) }
}

enum ToolLocator {
    static let searchDirs = ["/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin", "/usr/bin", "/bin", "/usr/sbin"]

    static func find(_ tool: Tool) -> String? {
        if tool == .soffice {
            let candidates = [
                "/Applications/LibreOffice.app/Contents/MacOS/soffice",
                NSHomeDirectory() + "/Applications/LibreOffice.app/Contents/MacOS/soffice",
            ]
            if let p = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) { return p }
        }
        return find(named: tool.rawValue)
    }

    static func find(named name: String) -> String? {
        searchDirs.map { "\($0)/\(name)" }.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}

struct ConversionError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

/// Runs a command, throwing with the tail of stderr on failure. Output goes to temp files (no pipe deadlocks).
@discardableResult
func runCommand(_ exe: String, _ args: [String], cwd: URL? = nil, extraEnv: [String: String] = [:]) throws -> String {
    let fm = FileManager.default
    let process = Process()
    process.executableURL = URL(fileURLWithPath: exe)
    process.arguments = args
    if let cwd { process.currentDirectoryURL = cwd }

    var env = ProcessInfo.processInfo.environment
    env["PATH"] = (ToolLocator.searchDirs + [env["PATH"] ?? ""]).joined(separator: ":")
    for (k, v) in extraEnv { env[k] = v }
    process.environment = env

    let outURL = fm.temporaryDirectory.appendingPathComponent("dw-\(UUID().uuidString).out")
    let errURL = fm.temporaryDirectory.appendingPathComponent("dw-\(UUID().uuidString).err")
    fm.createFile(atPath: outURL.path, contents: nil)
    fm.createFile(atPath: errURL.path, contents: nil)
    let outHandle = try FileHandle(forWritingTo: outURL)
    let errHandle = try FileHandle(forWritingTo: errURL)
    defer {
        try? outHandle.close(); try? errHandle.close()
        try? fm.removeItem(at: outURL); try? fm.removeItem(at: errURL)
    }
    process.standardOutput = outHandle
    process.standardError = errHandle
    process.standardInput = FileHandle.nullDevice

    try process.run()
    process.waitUntilExit()

    let out = (try? String(contentsOf: outURL, encoding: .utf8)) ?? ""
    if process.terminationStatus != 0 {
        let err = (try? String(contentsOf: errURL, encoding: .utf8)) ?? ""
        let tail = err.split(separator: "\n").suffix(3).joined(separator: " ")
        let name = URL(fileURLWithPath: exe).lastPathComponent
        throw ConversionError("\(name) failed: \(tail.isEmpty ? "exit code \(process.terminationStatus)" : tail)")
    }
    return out
}
