import Foundation

enum TerminalApplication: String, CaseIterable, Identifiable {
    case system, iterm2, ghostty, warp

    var id: String { rawValue }
    var name: String {
        switch self {
        case .system: return L10n.text("系统终端")
        case .iterm2: return "iTerm2"
        case .ghostty: return "Ghostty"
        case .warp: return "Warp"
        }
    }
    var bundleID: String {
        switch self {
        case .system: return "com.apple.Terminal"
        case .iterm2: return "com.googlecode.iterm2"
        case .ghostty: return "com.mitchellh.ghostty"
        case .warp: return "dev.warp.Warp-Stable"
        }
    }

    func openURL(for directory: URL) throws -> URL {
        guard directory.isFileURL, directory.path.hasPrefix("/"), !directory.path.utf8.contains(0) else {
            throw TerminalPreferenceError.invalidDirectory
        }
        guard self == .warp else { return directory }
        // Warp documents a dedicated directory URI. Never interpolate a shell command.
        var parts = URLComponents()
        parts.scheme = "warp"
        parts.host = "action"
        parts.path = "/new_window"
        parts.queryItems = [URLQueryItem(name: "path", value: directory.path)]
        // Form-style URL parsers can interpret a literal + as a space.
        parts.percentEncodedQuery = parts.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        guard let url = parts.url else { throw TerminalPreferenceError.invalidDirectory }
        return url
    }
}

enum TerminalPreference {
    static let key = "preferredTerminal.v1"

    static func load(from defaults: UserDefaults, legacyUser: Bool, itermInstalled: Bool) -> TerminalApplication {
        if let saved = defaults.string(forKey: key) {
            return TerminalApplication(rawValue: saved) ?? .system
        }
        let initial: TerminalApplication = legacyUser && itermInstalled ? .iterm2 : .system
        defaults.set(initial.rawValue, forKey: key)
        return initial
    }

    static func resolve(_ preferred: TerminalApplication, installed: Set<TerminalApplication>) throws -> TerminalApplication {
        if installed.contains(preferred) { return preferred }
        if installed.contains(.system) { return .system }
        throw TerminalPreferenceError.unavailable
    }
}

enum TerminalPreferenceError: LocalizedError {
    case invalidDirectory, unavailable
    var errorDescription: String? {
        switch self {
        case .invalidDirectory: return L10n.text("无法打开无效的终端目录。")
        case .unavailable: return L10n.text("没有找到可用的终端，请检查系统终端是否存在。")
        }
    }
}
