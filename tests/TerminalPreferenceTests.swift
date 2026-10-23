import Foundation

@main
struct TerminalPreferenceTests {
    static func main() throws {
        let suite = "com.inexom.zrightclick.tests.terminal.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        func reset() { defaults.removePersistentDomain(forName: suite) }
        precondition(TerminalPreference.load(from: defaults, legacyUser: false, itermInstalled: true) == .system)
        precondition(defaults.string(forKey: TerminalPreference.key) == "system")
        reset()
        precondition(TerminalPreference.load(from: defaults, legacyUser: true, itermInstalled: true) == .iterm2)
        // Installation changes must never silently rewrite a stored preference.
        precondition(TerminalPreference.load(from: defaults, legacyUser: true, itermInstalled: false) == .iterm2)
        reset()
        precondition(TerminalPreference.load(from: defaults, legacyUser: true, itermInstalled: false) == .system)
        defaults.set("warp", forKey: TerminalPreference.key)
        precondition(TerminalPreference.load(from: defaults, legacyUser: true, itermInstalled: true) == .warp)
        defaults.set("malicious.bundle.id", forKey: TerminalPreference.key)
        precondition(TerminalPreference.load(from: defaults, legacyUser: true, itermInstalled: true) == .system)

        for application in TerminalApplication.allCases {
            let available: Set<TerminalApplication> = [.system, application]
            let selected = try TerminalPreference.resolve(application, installed: available)
            precondition(selected == application)
            let missing = try TerminalPreference.resolve(application, installed: [.system])
            precondition(missing == .system)
        }
        do {
            _ = try TerminalPreference.resolve(.warp, installed: [.iterm2])
            preconditionFailure("Missing selected app and system terminal must report an error")
        } catch TerminalPreferenceError.unavailable { }

        for path in ["/tmp/中文 空格", "/tmp/a&b?#%+'\"", "/tmp/line\nbreak", "/"] {
            let directory = URL(fileURLWithPath: path, isDirectory: true)
            for application in [TerminalApplication.system, .iterm2, .ghostty] {
                let url = try application.openURL(for: directory)
                precondition(url == directory)
            }
            let url = try TerminalApplication.warp.openURL(for: directory)
            let parts = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            precondition(parts.scheme == "warp" && parts.host == "action" && parts.path == "/new_window")
            precondition(parts.queryItems == [URLQueryItem(name: "path", value: directory.path)])
            precondition(!url.absoluteString.contains("+"))
            precondition(parts.fragment == nil && parts.user == nil && parts.port == nil)
        }
        do {
            _ = try TerminalApplication.system.openURL(for: URL(string: "https://example.com")!)
            preconditionFailure("Only local directory URLs are allowed")
        } catch TerminalPreferenceError.invalidDirectory { }
        print("TerminalPreference tests passed: migration, persistence, fallback, and safe directory URLs")
    }
}
